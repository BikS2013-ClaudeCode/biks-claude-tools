# Database Table Naming

> Personal working rule, loaded in every project via `~/.claude/rules`.

- When designing databases, table names must be singular (e.g. the table keeping customers' data is `Customer`).
- Tables expressing references from one entity to another may be plural when the first entity links to many of the second — so with `Customer` and `Transaction` tables, the link table is `CustomerTransactions`.
