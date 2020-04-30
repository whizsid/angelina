# angelina

An ORM library for Ballerina Lang. This module is under development. You can not use it.

## Define Your Model

```ballerina
import ballerina/time;
import whizsid/angelina;

@angelina:Entity
type Student record {
    public int id;
    public string name;
    public time:Time createdTime;
}
```
