/**
 * @file ramble.cpp
 * @brief The implementation of the main function for ramble,
 *        and other functions that drive the program execution.
 * @author Ankit Srivastava <asrivast@gatech.edu>
 *
 * Copyright 2020 Georgia Institute of Technology
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include "ramble/ProgramOptions.hpp"
#include "ramble/learn_bn.hpp"

#include "common/DataReader.hpp"
#include "common/HDF5DataReader.hpp"
#include "mxx/env.hpp"
#include "utils/Logging.hpp"
#include "utils/Timer.hpp"

#include <boost/asio/ip/host_name.hpp>

#include <iostream>
#include <memory>
#include <vector>


void
warmupMPI(
  const mxx::comm& comm
)
{
  std::vector<uint8_t> send(comm.size());
  std::vector<uint8_t> recv(comm.size());
  // First, warmup Alltoall of size 1
  mxx::all2all(&send[0], 1, &recv[0], comm);
  // Then, warmup Alltoallv of size 1
  std::vector<size_t> sendSizes(comm.size(), 1);
  std::vector<size_t> sendDispls(comm.size());
  std::iota(sendDispls.begin(), sendDispls.end(), 0);
  std::vector<size_t> recvSizes(comm.size(), 1);
  std::vector<size_t> recvDispls(sendDispls);
  mxx::all2allv(&send[0], sendSizes, sendDispls, &recv[0], recvSizes, recvDispls, comm);
}

int
main(
  int argc,
  char** argv
)
{
  // Set up MPI
  TIMER_DECLARE(tInit);

  mxx::env e(argc, argv);
  mxx::env::set_exception_on_error();
  mxx::comm comm;
  comm.barrier();
  if (comm.is_first()) {
    TIMER_ELAPSED("Time taken in initializing MPI: ", tInit);
  }


  ProgramOptions options;
  try {
    options.parse(argc, argv);
  }
  catch (const po::error& pe) {
    if (comm.is_first()) {
      std::cerr << pe.what() << std::endl;
    }
    return 1;
  }

  if (options.hostNames()) {
    auto name = boost::asio::ip::host_name();
    if (comm.is_first()) {
      std::cout << std::endl << "*** Host names ***" << std::endl;
      std::cout << comm.rank() << ": " << name << std::endl;
    }
    for (int i = 1; i < comm.size(); ++i) {
      if (comm.rank() == i) {
        comm.send(name, 0, i);
      }
      if (comm.is_first()) {
        name = comm.recv<std::string>(i, i);
        std::cout << i << ": " << name << std::endl;
      }
    }
    if (comm.is_first()) {
      std::cout << "******" << std::endl;
    }
  }

  if ((comm.size() > 1) && options.warmupMPI()) {
    comm.barrier();
    TIMER_DECLARE(tWarmup);
    warmupMPI(comm);
    comm.barrier();
    if (comm.is_first()) {
      TIMER_ELAPSED("Time taken in warming up MPI: ", tWarmup);
    }
  }

  try {
    std::string logFile = options.logFile();
    if (!logFile.empty() && (comm.size() > 1)) {
      logFile += ".p" + std::to_string(comm.rank());
    }
    INIT_LOGGING(logFile, comm.rank(), options.logLevel());
    uint32_t n = options.numVars();
    uint32_t m = options.numObs();
    if (static_cast<double>(m) >= std::sqrt(std::numeric_limits<uint32_t>::max())) {
      // Warn the user if the number of observations is too big to be handled by uint32_t
      // We use sqrt here because we never multiply more than two observation counts without handling the consequences
      std::cerr << "WARNING: The given number of observations is possibly too big to be handled by 32-bit unsigned integer" << std::endl;
      std::cerr << "         This may result in silent errors because of overflow" << std::endl;
    }
    TIMER_DECLARE(tRead);
    std::unique_ptr<DataReader<uint8_t>> reader;
    constexpr auto varMajor = true;
    const std::string& filename = options.dataFile();
    if ((endsWith(filename, "hdf5")) || (endsWith(filename, ".h5")) || 
        (endsWith(filename, ".loom")) || (endsWith(filename, ".h5ad"))){
      reader.reset(new HDF5ObservationReader<uint8_t>(options.dataFile(), n, m, 
                                                      options.h5root(),
                                                      options.h5matrixPath(),
                                                      options.h5obsPath(),
                                                      options.h5varPath(),
                                                      options.parallelRead()));
    } else if (options.colObs()) {
      reader.reset(new ColumnObservationReader<uint8_t>(options.dataFile(), n, m, options.separator(),
                                                        options.varNames(), options.obsIndices(), varMajor, options.parallelRead()));
    }
    else {
      reader.reset(new RowObservationReader<uint8_t>(options.dataFile(), n, m, options.separator(),
                                                     options.varNames(), options.obsIndices(), varMajor, options.parallelRead()));
    }
    comm.barrier();
    if (comm.is_first()) {
      TIMER_ELAPSED("Time taken in reading the file: ", tRead);
    }
    TIMER_DECLARE(tLearnBN);
    learnBN(n, m, std::move(reader), options, comm);
    if (comm.is_first()) {
      TIMER_ELAPSED("Time taken in learn Bayesian Network: ", tLearnBN);
    }
  }
  catch (const std::runtime_error& e) {
    std::cerr << "Encountered runtime error during execution:" << std::endl;
    std::cerr << e.what() << std::endl;
    std::cerr << "Aborting." << std::endl;
    return 1;
  }

  return 0;
}
