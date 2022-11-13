

# Variable naming conventions

There are three kinds of variable used in this project:
- `local_variables`
    - These are used to store temporary information, and are used as if they're scoped. They're not scoped. Bash isn't a programming language.
    - When possible, use these with the local keyword.
- `Global_Configuration_Variables`
    - These are used to store information that needs to be easily accessible by everything. Generally related to the config file.
- `GLOBAL_STATE_FLAGS`
    - These are used when a variable needs to persist between runs of a single function, and carry information about the so-called-program state
