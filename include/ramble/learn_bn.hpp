#ifndef LEARN_NETWORK_HPP
#define LEARN_NETWORK_HPP

#include <memory>
#include "ramble/ProgramOptions.hpp"
#include "common/DataReader.hpp"

void learnBN
(
  const uint32_t n,
  const uint32_t m,
  std::unique_ptr<DataReader<uint8_t>>&& reader,
  const ProgramOptions& options,
  const mxx::comm& comm
);

#if __cplusplus >= 201703L // C++17 and later 
#include <string_view>
bool endsWith(std::string_view str, std::string_view suffix);
#else  // C++ 14 and earlier.
#include <string>
bool endsWith(const std::string& str, const char* suffix, unsigned suffixLen);
bool endsWith(const std::string& str, const char* suffix);
#endif



#endif // !LEARN_NETWORK_HPP
