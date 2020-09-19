// Query builder and related types.
import ballerinax/java.jdbc;

# Logical Operators
public type LogicalOperator AND|OR|EMPTY;
public const AND = "AND";
public const OR = "OR";
public const EMPTY = "";

# Angelina condition
# 
# + operator - The operator that you comparing right side and left side
# + right - Right side
# + left - Left side
# + prefixedLogicalOperator - The logical operator that combine with previous condition
public type Condition record {
    string operator;
    UseAsValue right;
    UseAsValue left;
    LogicalOperator prefixedLogicalOperator = EMPTY;
};

# Condition set using for WHERE clause
public type WhereClause object {
    (Condition|WhereClause)[] childs = [];
    LogicalOperator prefixedLogicalOperator = EMPTY;

    public function __init() {
    }

    public function start(UseAsValue left, string operator, UseAsValue right, LogicalOperator lo = AND) {
        self.childs.push(<Condition>{
            left,
            right,
            operator
        });
        self.prefixedLogicalOperator = lo;
    }

    # Create a condition and combine it with AND operator
    # 
    # <code>
    # WHERE foo!=1 AND bar = 2
    # </code>
    # 
    # + left - Left side of the condition
    # + operator - Operator that using to compare left side and right side
    # + right - Right side of the condition
    # + return - The condition set
    public function and(UseAsValue left, string operator, UseAsValue right) returns WhereClause {

        self.childs.push(<Condition>{
            left,
            right,
            operator,
            prefixedLogicalOperator: AND
        });

        return self;
    }

    # Create a condition and combine it with OR operator
    # 
    # <code>
    # WHERE foo!=1 OR bar = 2
    # </code>
    # 
    # + left - Left side of the condition
    # + operator - Operator that using to compare left side and right side
    # + right - Right side of the condition
    # + return - The condition set
    public function or(UseAsValue left, string operator, UseAsValue right) returns WhereClause {
        self.childs.push(<Condition>{
            left,
            right,
            operator,
            prefixedLogicalOperator: OR
        });

        return self;
    }

    # Create a sub condition set and combine it with AND operator
    # 
    # These conditions are rendering inside parentheses.
    # 
    # <code>
    # WHERE foo!=1 OR (bar =2 AND foo = 1)
    # </code>
    # 
    # + left - Left side of the condition
    # + operator - Operator that using to compare left side and right side
    # + right - Right side of the condition
    # + return - Child condition set
    public function andSub(UseAsValue left, string operator, UseAsValue right) returns WhereClause {
        WhereClause child = new ();
        child.start(left, operator, right, AND);

        self.childs.push(child);

        return child;
    }

    # Create a sub condition set and combine it with OR operator
    # 
    # These conditions are rendering inside parentheses.
    # 
    # <code>
    # WHERE foo!=1 OR (bar =2 AND foo = 1)
    # </code>
    # 
    # + left - Left side of the condition
    # + operator - Operator that using to compare left side and right side
    # + right - Right side of the condition
    # + return - Child condition set
    public function orSub(UseAsValue left, string operator, UseAsValue right) returns WhereClause {
        WhereClause child = new ();

        child.start(left, operator, right, OR);

        self.childs.push(child);

        return child;
    }

    public function getQuery() returns AngelinaQuery {
        AngelinaQuery query = new();

        int i = 0;
        foreach var child in self.childs {
            if child is Condition {
                if (i != 0) {
                    query.concat_raw(child.prefixedLogicalOperator);
                }

                AngelinaQuery leftPart = render(child.left);
                query.concat(leftPart);

                query.concat_raw(child.operator);

                AngelinaQuery rightPart = render(child.right);
                query.concat(rightPart);

            } else {
                if (i != 0) {
                    query.concat_raw(child.prefixedLogicalOperator);
                }

                AngelinaQuery subQuery = child.getQuery();
                query.concat_raw("(");
                query.concat(subQuery);
                query.concat_raw(")");
            }

            i = i + 1;
        }

        return query;
    }

    # Determining the weather that condition set is empty
    # 
    # + return - Empty or not
    public function isEmpty() returns boolean {
        return self.childs.length() == 0;
    }
};

# Condition Set for table joining. Same as where clause
public type OnClause WhereClause;

# Join Modes
public type JoinMode LEFT_OUTER|RIGHT_OUTER|RIGHT|LEFT|STRAIGHT_JOIN|CROSS|INNER;
public const LEFT_OUTER = "LEFT OUTER";
public const RIGHT_OUTER = "RIGHT OUTER";
public const CROSS = "CROSS";
public const LEFT = "LEFT";
public const RIGHT = "LEFT";
public const INNER = "INNER";
public const STRAIGHT_JOIN = "STRAIGHT JOIN";

public type JoinClause object {
    public JoinMode mode;
    public UseAsTable tableOrSubQuery;
    public WhereClause onClause = new ();
    public UseAsColumn [] usingClause = [];

    public function __init(JoinMode mode, UseAsTable tableOrSubQuery){
        self.mode = mode;
        self.tableOrSubQuery = tableOrSubQuery;
    }

    public function onWhere(UseAsValue left, string operator, UseAsValue right) returns WhereClause {
        self.onClause.start(left, operator, right);
        return self.onClause;
    }

    public function using(UseAsColumn [] columns){
        self.usingClause = columns;
    }
};

# Update query new values
# 
# + column - Column name
# + param - Value
type NewValue record {
    Column column;
    UseAsValue param;
};

public type QueryMode SELECT_QUERY|UPDATE_QUERY|DELETE_QUERY|INSERT_QUERY;
public const SELECT_QUERY = "SELECT_QUERY";
public const UPDATE_QUERY = "UPDATE_QUERY";
public const DELETE_QUERY = "DELETE_QUERY";
public const INSERT_QUERY = "INSERT_QUERY";

public type OrderByMode ASC|DESC;
public const ASC = "ASC";
public const DESC = "DESC";

public type OrderBy record {
    UseAsValue column;
    OrderByMode mode;
};

public type AngelinaQuery object {
    string query;
    jdbc:Param[] parameters = [];

    public function __init(string query = "", jdbc:Param[] parameters = []) {
        self.query = query;
        self.parameters = parameters;
    }

    public function concat( AngelinaQuery query ){
        self.concat_raw(query.query);


        foreach var param in query.parameters {
            self.parameters.push(param);
        }
    }

    public function concat_raw(string query){
        if(self.query!=""){
            self.query = self.query.concat(" ");
        }

        self.query = self.query.concat(query);
    }

    public function copy() returns AngelinaQuery{
        return new(self.query, self.parameters);
    }
};

# Angelina Query Builder
public type Builder client object {
    jdbc:Client jdbcClient;
    private QueryMode mode = SELECT_QUERY;
    # Main table name
    private UseAsTable tableName = t("");
    # Where cluase for Update\ Select\ Delete queries
    private WhereClause where = new ();
    private JoinClause[] joins = [];
    # Update query new values
    private NewValue[] newValues = [];
    # Insert query columns
    private Column[] insertColumns = [];
    # Insert query values sets
    private jdbc:Param[][] values = [];
    # Select query columns or aliases
    private UseAsColumn[] selectColumns = [];
    # Order by clause
    private OrderBy[] orderByColumns = [];
    # Having clause
    private WhereClause havingClause = new ();

    public function __init(jdbc:Client c, UseAsTable tableName) {
        self.tableName = tableName;
        self.jdbcClient = c;
    }

    # Set clause in update query
    # 
    # + column - Column name
    # + value - New value
    public function set(Column column, UseAsValue value) {
        self.newValues.push(<NewValue>{
            column: column,
            param: value
        });
    }

    # Making a query as a select query
    # 
    # + columns - Column names or aliases for select clause
    public function select(UseAsColumn[] columns) {
        self.mode = SELECT_QUERY;
        self.selectColumns = columns;
    }

    # Making the as an update query
    public function update() {
        self.mode = UPDATE_QUERY;
    }

    # Making the query as a insert query
    # 
    # + columns - Column list for insert query
    # + values - Value sets
    public function insert(Column[] columns, Value[][] values) {
        self.insertColumns = columns;
        self.values = values;
        self.mode = INSERT_QUERY;
    }

    # Making the query as a delete query
    public function delete() {
        self.mode = DELETE_QUERY;
    }

    public function where(UseAsValue left, string operator, UseAsValue right) returns WhereClause {
        self.where.start(left, operator, right);

        return self.where;
    }

    # Perform a join
    # 
    # + joinMode - `LEFT_OUTER|RIGHT_OUTER|RIGHT|LEFT|STRAIGHT_JOIN|CROSS|INNER`
    # + tableOrSubquery - Table to join
    # + return - Condition set. You can use more than one conditions in on clause.
    public function joinTable(JoinMode joinMode,UseAsTable tableOrSubquery)
    returns JoinClause {
        JoinClause joinClause = new(joinMode, tableOrSubquery);

        self.joins.push(joinClause);

        return joinClause;
    }

    # Adding a column to the order by clause
    # 
    # You can call it multiple times to add multiple columns
    # 
    # + column - Column name or function
    # + mode - Order mode
    public function orderBy(UseAsValue column, OrderByMode mode) {
        self.orderByColumns.push(<OrderBy>{
            column,
            mode
        });
    }

    # Adding a having clause
    # 
    # + left - Left side of the first condition
    # + operator - Operator using for the condition
    # + right - Right side of the condition
    # + return - Angelina Condition Set
    public function having(UseAsValue left, string operator, UseAsValue right) returns WhereClause {
        self.havingClause.start(left, operator, right);
        return self.havingClause;
    }

    public function getQuery() returns AngelinaQuery {
        AngelinaQuery query = new();

        match self.mode {
            INSERT_QUERY => {
                query.concat_raw("INSERT INTO");
            }
            UPDATE_QUERY => {
                query.concat_raw("UPDATE");
            }
            SELECT_QUERY => {
                query.concat_raw("SELECT");
            }
            DELETE_QUERY => {
                query.concat_raw("DELETE FROM");
            }
        }

        // Table Name
        if (self.mode != SELECT_QUERY) {
            AngelinaQuery subQuery = render(self.tableName);
            query.concat(subQuery);
        }

        // Select Clause
        if (self.mode == SELECT_QUERY) {
            // Render select column list
            int i = 0;
            foreach var col in self.selectColumns {
                AngelinaQuery subQuery = render(col);

                if (i != 0) {
                    query.concat_raw(",");
                }

                query.concat(subQuery);
                i = i + 1;
            }

            if (self.selectColumns.length() == 0) {
                query.concat_raw("*");
            }

            // Render table
            query.concat_raw("FROM");

            AngelinaQuery subQuery = render(self.tableName);

            query.concat(subQuery);
        }

        // Set Clause
        if (self.mode == UPDATE_QUERY) {
            query.concat_raw("SET");

            int i = 0;
            foreach var newValue in self.newValues {
                if (i != 0) {
                    query.concat_raw(",");
                }

                AngelinaQuery column_name = render(newValue.column);
                query.concat(column_name);

                query.concat_raw("=");

                AngelinaQuery param_val = render(newValue.param);
                query.concat(param_val);

                i = i + 1;
            }
        }

        // Join Clause
        if (self.mode != INSERT_QUERY) {
            foreach var joinClause in self.joins {
                query.concat_raw(joinClause.mode);

                query.concat_raw("JOIN");

                AngelinaQuery subQuery = render(joinClause.tableOrSubQuery);
                query.concat(subQuery);

                if (joinClause.mode != CROSS) {
                    query.concat_raw("ON");

                    WhereClause conditions = joinClause.onClause;

                    if (!conditions.isEmpty()) {
                        AngelinaQuery onClause = conditions.getQuery();
                        query.concat( onClause);
                    }
                }

                if(joinClause.usingClause.length()!=0){
                    query.concat_raw("USING (");

                    int i = 0;
                    foreach var col in joinClause.usingClause {
                        if(i!=0){
                            query.concat_raw(",");
                        }

                        query.concat(render(col));
                    }

                    query.concat_raw(")");
                }
            }
        }

        // Where clause
        if (self.mode != INSERT_QUERY) {
            WhereClause whereClause = self.where;
            if (!whereClause.isEmpty()) {
                query.concat_raw("WHERE");

                AngelinaQuery where = whereClause.getQuery();
                query.concat(where);
            }
        }

        // Insert query
        if (self.mode == INSERT_QUERY) {
            query.concat_raw("(");

            int i = 0;

            foreach var insertColumn in self.insertColumns {
                if (i != 0) {
                    query.concat_raw(",");
                }

                AngelinaQuery insertColumnQuery = render(insertColumn);
                query.concat(insertColumnQuery);
                i = i + 1;
            }

            query.concat_raw(") VALUES");

            i = 0;
            foreach var valueSet in self.values {
                if (i != 0) {
                    query.concat_raw(",");
                }

                query.concat_raw("(");

                int j = 0;
                foreach var value in valueSet {
                    if (j != 0) {
                        query.concat_raw(",");
                    }

                    AngelinaQuery val = render(v(value));

                    query.concat(val);
                    j = j + 1;
                }

                query.concat_raw(")");

                i = i + 1;
            }
        }



        return query;
    }

    public remote function get() returns @tainted table<record {|anydata...;|}>|error {
        AngelinaQuery query = self.getQuery();
        if (self.mode == SELECT_QUERY) {
            return self.jdbcClient->select(query.query, typedesc<record {|anydata...;|}>, ...query.parameters);
        } else {
            return error("Angelina: Please use execute method to execute update/insert/delete queries.");
        }
    }

    public remote function execute() returns @tainted jdbc:UpdateResult|error {
        AngelinaQuery query = self.getQuery();
        if (self.mode != SELECT_QUERY) {
            return self.jdbcClient->update(query.query, ...query.parameters);
        } else {
            return error("Angelina: Please use get method to select data.");
        }
    }

};

# Angelina alias
# 
# + ref - The reference that you aliasing
# + alias - Alias
public type Alias record {
    Table | Column | Value | Builder ref;
    string alias;
};

# Angelina table
# 
# + tableName - Table Name
public type Table record {
    string tableName;
};

# Angelina value
# 
# + value - Value to passed
public type Value record {
    jdbc:Param value;
};

# Angelina column
# 
# + columnName - Columne name
public type Column record {
    string columnName;
};

# This type can use as a value for queries
public type UseAsValue Column | Value ;

# This type can use as a column for queries 
# 
# Please use an alias (`a()`) if you want to use a value as a column 
public type UseAsColumn Alias | Column;

# This type can use as a table for queries
# 
# Please use an alias (`a()`) if you want to use a sub query as a table 
public type UseAsTable Alias | Table;

# Making an angelina table
# 
# + tableName - Table name
# + return - Angelina table object
public function t(string tableName) returns Table{
    return {
        tableName
    };
}

# Making an angelina column
# 
# + columnName - Column name
# + return - Angelina column object
public function c(string columnName) returns Column{
    return {
        columnName
    };
}

# Making an angelina value
# 
# + value - Actual value
# + return - Angelina value object
public function v(jdbc:Param value) returns Value{
    return {value};
}

# Making an angelina alias
# 
# + ref - Column/ Table / Value / Sub Query
# + alias - New alias
# + return - Angelina alias
public function a(Table | Column | Value | Builder ref, string alias) returns Alias {
    return {
        ref,
        alias
    };
}

function render(Table | Column | Value | Alias obj) returns AngelinaQuery{
    if obj is Table {
        return new(obj.tableName, []);
    } else if obj is Column {
        return new(obj.columnName, []);
    } else if obj is Value {
        return new("?",[obj.value]);
    } else {
        Builder | Table | Column | Value ref = obj.ref;

        if ref is Builder {
            AngelinaQuery query = new();
            query.concat_raw("(");
            AngelinaQuery subQuery =  ref.getQuery();
            query.concat(subQuery);
            query.concat_raw(")");

            query.concat_raw("AS");
            query.concat_raw(obj.alias);

            return query;
        } else {
            AngelinaQuery query = new();
            AngelinaQuery subQuery = render(ref);
            query.concat(subQuery);

            query.concat_raw("AS");
            query.concat_raw(obj.alias);

            return query;
        }
    }
}