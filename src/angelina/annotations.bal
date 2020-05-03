// Annotations and related types

import ballerinax/java.jdbc;

# Use it for define one to many relationships
# + name - Name of the relationship (Same as the field name of the entity type)
# + entity - The entity type. This entity should also annotated
# + otherKey - Column name of the other table key (Same as the field name of the other entity type)
# + foreignKey - Column name of the foreign key (Same as the field name of the foreign key)
public type OneToManyRelation record {
    string name;
    typedesc<map<anydata>> entity;
    string otherKey;
    string foreignKey;
};

# Use it for define many to one relationships
# + name - Name of the relationship (Same as the field name of the entity type)
# + entity - The entity type. This entity should also annotated
# + otherKey - Column name of the other table key (Same as the field name of the other entity type)
# + foreignKey - Column name of the foreign key (Same as the field name of the foreign key)
public type ManyToOneRelation record {
    string name;
    typedesc<map<anydata>> entity;
    string otherKey;
    string foreignKey;
};

# Many to many relations
# + name - Name of the relationship (Same as the field name of the entity type)
# + entity - The entity type. This entity should also annotated
# + otherKey - The column name of the foreign key used in the other entity (Same as the field name of the other entity that you supplied)
# + foreignKey - The column name of the foreign key in current entity (Same as the field name of the entity)
# + mapTableName - The name of the table that we using to map both entities
# + mapOtherKey - The column name of the key in mapping table that referencing the foreign key of the other table.
# + mapForeignKey - The column name of the key in mapping table that referencing the foreign key of the current table.
public type ManyToManyRelation record {
    string name;
    typedesc<map<anydata>> entity;
    string otherKey;
    string foreignKey;
    string mapTableName;
    string mapOtherKey?;
    string mapForeignKey?;
};

public type Relation OneToManyRelation | ManyToOneRelation | ManyToManyRelation;

# Anntate all entities with this type
# + tableName - Table name that using for the entity
# + primary - Primary column name of the entity
# + fields - Column names and types.
# + relations - Relations for other entities
public type EntityType record {|
    string tableName;
    string primary;
    map<jdbc:SQLType> fields = {};
    map<Relation> relations = {};
|};

public annotation EntityType Entity on type;