# Usage

This tool is meant to be used in conjunction with https://github.com/adamtopaz/leannldata. Please see the README there for more information on how to get started.
With the API from that repo running properly, you can use this package as a dependency in your Lean4 project as usual, and write 
```lean
#find_with_gpt "Some text."
```
When writing the string, the search will only be initiated once the string contains a period (anywhere in the string).
