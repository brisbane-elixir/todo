# Elixir in Action Part 1

This project is the result of working through the practical examples in Elixir in Action, by Sasa Juric
https://www.manning.com/books/elixir-in-action

We'll work through the material over several meetups:
 - 2016-08-04: [Part 1](./elixir_in_action_part_1.md)
 - 2016-09-29: [Part 2](./elixir_in_action_part_2.md)
 - 2016-11-03: [Part 3](./elixir_in_action_part_3.md)

We'll work through the hands-on excerises from this book, would build a ToDo server application.
The concept of the application is simple enough. The basic version of the to-do list will support the following features:
 - Creating a new data abstraction
 - Adding new entries
 - Querying the abstraction
We'll continue adding features and by the end we’ll have a fully working distributed web server that can manage a large number of to-do
lists.

### Overview
 - Todo list data abstraction
 - Server Processes
    - Todo generic server process
    - GenServer powered Todo server
 - Building a concurrent system
    - Managing multiple Todo lists
    - Persisting data
    - Analysing and addressing bottlenecks
 - Fault tolerance
    - Errors in concurrent systems
    - Supervisors and Supervision trees
    - Isolating error effects
 - Sharing state
    - Single process bottlenecks
    - ETS Tables
 - Production
    - Working with components
    - Building and running the distributed system
