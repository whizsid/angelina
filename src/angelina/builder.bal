// Query builder and related types.
import ballerinax/java.jdbc;

public const COLUMN = "COLUMN";
public const VALUE = "VALUE";

public type Parameter record {
    COLUMN|VALUE parameterType;
    jdbc:Param value;
};

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
    Parameter right;
    Parameter left;
    LogicalOperator prefixedLogicalOperator =  EMPTY;
};

# Angelina condition set using for WHERE clause and ON clause
public type ConditionSet object {
    (Condition|ConditionSet)[] childs = [];
    LogicalOperator prefixedLogicalOperator = EMPTY;

    public function __init(){
    }

    public function start(Parameter left, string operator, Parameter right, LogicalOperator lo = AND) {
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
    public function and(Parameter left, string operator, Parameter right) returns ConditionSet {

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
    public function or(Parameter left, string operator, Parameter right) returns ConditionSet {
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
    public function andSub(Parameter left, string operator, Parameter right) returns ConditionSet {
        ConditionSet child = new();
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
    public function orSub(Parameter left, string operator, Parameter right) returns ConditionSet {
        ConditionSet child = new();
        
        child.start(left, operator, right, OR);

        self.childs.push(child);

        return child;
    }

    public function getQuery() returns AngelinaQuery {
        jdbc:Param[] parameters = [];

        string query = "";

        int i=0;
        foreach var child in self.childs {
            if child is Condition {
                if(i!=0){
                        query = concat(query, child.prefixedLogicalOperator);
                }
                
                if(child.left.parameterType==VALUE){
                    query = query.concat("? ");
                    parameters.push(child.left.value);
                } else {
                    query = query.concat(child.left.value.toString());
                }
                query = concat(query, child.operator);

                if(child.right.parameterType==VALUE){
                    query = query.concat("? ");
                    parameters.push(child.right.value);
                } else {
                    query = query.concat(child.right.value.toString());
                }

            } else {
                if(i!=0){
                    query = concat(query,child.prefixedLogicalOperator);
                }

                AngelinaQuery subQuery = child.getQuery();
                query = query.concat("( "+ subQuery.query+" )");

                foreach var param in subQuery.parameters {
                    parameters.push(param);
                }
            }

            i = i+1;
        }

        return {
            query,
            parameters
        };
    }

    # Determining the weather that condition set is empty
    # 
    # + return - Empty or not
    public function isEmpty() returns boolean {
        return self.childs.length() == 0;
    }
};

# Join Modes
public type JoinMode LEFT_OUTER|CROSS|INNER;
public const LEFT_OUTER = "LEFT_OUTER";
public const CROSS = "CROSS";
public const INNER = "INNER";

type TableJoin record {
    JoinMode mode;
    string|Alias tableOrSubQuery;
    ConditionSet conditions = new();
};

# Update query new values
# 
# + column - Column name
# + param - Value
type NewValue record {
    string column;
    jdbc:Param param;
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
    string column;
    OrderByMode mode;
};

public type AngelinaQuery record {
    string query;
    jdbc:Param[] parameters = [];
};

function concat(string str, string part) returns string {
    string new_str = str.concat(" ");
    new_str = new_str.concat(part);

    return new_str;
}

# Angelina Query Builder
public type Builder client object {
    jdbc:Client jdbcClient;
    private QueryMode mode = SELECT_QUERY;
    # Main table name
    private string|Alias tableName = "";
    # Where cluase for Update\ Select\ Delete queries
    private ConditionSet where = new();
    private TableJoin[] joins = [];
    # Update query new values
    private NewValue[] newValues = [];
    # Insert query columns
    private string[] insertColumns = [];
    # Insert query values sets
    private jdbc:Param[][] values = [];
    # Select query columns or aliases
    private (string|Alias)[] selectColumns = [];
    # Order by clause
    private OrderBy[] orderByColumns = [];
    # Having clause
    private ConditionSet havingClause = new() ;

    public function __init(jdbc:Client c, string|Alias tableName) {
        self.tableName = tableName;
        self.jdbcClient = c;
    }

    # Set clause in update query
    # 
    # + column - Column name
    # + value - New value
    public function set(string column, jdbc:Param value) {
        self.newValues.push(<NewValue>{
            column: column,
            param: value
        });
    }

    # Executing a select query
    # 
    # + columns - Column names or aliases for select clause
    public function select((Alias|string)[] columns) {
        self.mode = SELECT_QUERY;
        self.selectColumns = columns;
    }

    # Execute the update query
    public function update() {
        self.mode = UPDATE_QUERY;
    }

    # Execute the insert query
    # 
    # + columns - Column list for insert query
    # + values - Value sets
    public function insert(string[] columns, jdbc:Param[][] values) {
        self.insertColumns = columns;
        self.values = values;
        self.mode = INSERT_QUERY;
    }

    # Perform a left join
    # 
    # + tableOrSubQuery - The table name/ aliased table name / aliased sub query
    # + left - Condition left side
    # + right - Condition right side
    # + operator - Operator that should use on condition
    # + return - Condition set. You can use more than one conditions in on clause.
    public function leftJoin(string|Alias tableOrSubQuery, Parameter left, string operator, Parameter right)
    returns ConditionSet {
        ConditionSet condition = new ();

        condition.start(left, operator, right);

        self.joins.push(<TableJoin>{
            mode: LEFT_OUTER,
            tableOrSubQuery: tableOrSubQuery
        });

        return condition;
    }

    # Perform a cross join
    # 
    # + tableOrSubQuery - The table name/ aliased table name / aliased sub query
    public function crossJoin(string|Alias tableOrSubQuery) {
        self.joins.push(<TableJoin>{
            mode: LEFT_OUTER,
            tableOrSubQuery: tableOrSubQuery,
            conditions: new()
        });
    }

    # Perform a inner join
    # 
    # + tableOrSubQuery - The table name/ aliased table name / aliased sub query
    # + left - Condition left side
    # + right - Condition right side
    # + operator - Operator that should use on condition
    # + return - Condition set. You can use more than one conditions in on clause.
    public function innerJoin(string|Alias tableOrSubQuery, Parameter left, string operator, Parameter right)
    returns ConditionSet {
        ConditionSet condition = new();

        condition.start(left, operator, right);

        self.joins.push(<TableJoin>{
            mode: INNER,
            tableOrSubQuery: tableOrSubQuery,
            conditions: condition
        });

        return condition;
    }

    # Adding a column to the order by clause
    # 
    # You can call it multiple times to add multiple columns
    # 
    # + column - Column name or function
    # + mode - Order mode
    public function orderBy(string column, OrderByMode mode) {
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
    public function having(Parameter left, string operator, Parameter right) returns ConditionSet {
        ConditionSet having = new();

        having.start(left, operator, right);
        self.havingClause = having;
        return having;
    }


    public function getQuery() returns AngelinaQuery {
        jdbc:Param[] parameters = [];
        string query = "";

        match self.mode {
           INSERT_QUERY => {
                query = query.concat("INSERT INTO");
            }
           UPDATE_QUERY => {
                query = query.concat("UPDATE");
            }
           SELECT_QUERY => {
                query = query.concat("SELECT");
            }
           DELETE_QUERY => {
                query = query.concat("DELETE FROM");
            }
        }

        // Table Name
        if (self.mode != SELECT_QUERY) {
            AngelinaQuery subQuery = renderAlias(self.tableName);
            query = concat(query,subQuery.query);

            foreach var param in subQuery.parameters {
                parameters.push(param);
            }
        }

        // Select Clause
        if (self.mode == SELECT_QUERY) {
            // Render select column list
            int i = 0;
            foreach var col in self.selectColumns {
                AngelinaQuery subQuery = renderAlias(col);

                if (i != 0) {
                    query = concat(query,",");
                }

                query = concat(query ,subQuery.query);

                foreach var param in subQuery.parameters {
                    parameters.push(param);
                }
                i = i + 1;
            }

            if(self.selectColumns.length()==0){
                query = concat(query, "*");
            }

            // Render table
            query = concat(query, "FROM");

            AngelinaQuery subQuery = renderAlias(self.tableName);
            
            query = concat(query,subQuery.query);

            foreach var param in subQuery.parameters {
                parameters.push(param);
            }
        }

        // Set Clause
        if (self.mode == UPDATE_QUERY) {
            query = concat(query, "SET");
            
            int i = 0;
            foreach var newValue in self.newValues {
                if(i!=0){
                    query= concat(query, ",");
                }
                query = concat(query ,newValue.column);
                query = concat( query ," = ?" );
                parameters.push(newValue.param);
                i = i+1;
            }
        }

        // Join Clause
        if (self.mode != INSERT_QUERY) {
            foreach var tableJoin in self.joins {
                query = concat(query, tableJoin.mode);

                AngelinaQuery subQuery = renderAlias(tableJoin.tableOrSubQuery);
                query = concat(query,subQuery.query);
                foreach var param in subQuery.parameters {
                    parameters.push(param);
                }

                if(tableJoin.mode!=CROSS){
                    query = concat(query,"ON");
                    ConditionSet conditions = tableJoin.conditions;

                    if(!conditions.isEmpty()){
                        AngelinaQuery onClause = conditions.getQuery();
                        query = concat(query, onClause.query);

                        foreach var param in onClause.parameters {
                            parameters.push(param);
                        }
                    }
                }
            }
        }

        // Where clause
        if (self.mode != INSERT_QUERY) {
            ConditionSet whereClause = self.where;
            if(!whereClause.isEmpty()){
                query = concat(query ,"WHERE");

                AngelinaQuery where = whereClause.getQuery();
                query = concat(query, where.query);

                foreach var param in where.parameters {
                    parameters.push(param);
                }
            }
        }

        // Insert query
        if (self.mode == INSERT_QUERY){
            query = concat(query, "(");

            int i = 0;
            foreach var insertColumn in self.insertColumns {
                if(i!=0){
                    query = concat(query, ",");
                }
                query = concat(query, insertColumn);
                i = i+1;
            }

            query = concat(query ,") VALUES");

            i = 0;
            foreach var valueSet in self.values {
                if(i!=0){
                    query = concat(query ,",");
                }

                query = concat(query ,"(");

                int j =0;
                foreach var value in valueSet {
                    if(j!=0){
                        query = concat(query, ",");
                    }
                    query = concat(query, "?");
                    j = j+1;
                }

                query = concat(query, ")");

                i=i+1;
            }
        }

        return {query, parameters};
    }

    public remote function get() returns @tainted table<record {|anydata...;|}> | error {
        AngelinaQuery query = self.getQuery();
        if(self.mode==SELECT_QUERY){
            return self.jdbcClient->select(query.query, typedesc<record {| anydata...; |}>, ...query.parameters);
        } else {
            return error("Angelina: Please use execute method to execute update/insert/delete queries.");
        }
    }

    public remote function execute() returns @tainted jdbc:UpdateResult | error {
        AngelinaQuery query = self.getQuery();
        if(self.mode!=SELECT_QUERY){
            return self.jdbcClient->update(query.query, ... query.parameters);
        } else {
            return error("Angelina: Please use get method to select data.");
        }
    }

};

# Converting normal column to an angelina column
# 
# + col - Column name
# + return - Angelina column
public function column(string col) returns Parameter {
    return {
        parameterType: COLUMN,
        value: col
    };
}

# Converting normal value to an angelina value
# 
# + val - Value
# + return - Angelina value
public function value(string val) returns Parameter {
    return {
        parameterType: VALUE,
        value: val
    };
}

# Angelina alias
# 
# + ref - The reference that you aliasing
# + alias - Alias
public type Alias record {
    string|Builder|jdbc:Param ref;
    string alias;
};

# Aliasing a column name/ table name or sub query
# 
# + ref - Column name/ table name or sub query
# + alias - New alias
# + return - Angelina alias
public function alias(string|Builder|jdbc:Param ref, string alias) returns Alias {
    return {
        ref,
        alias
    };
}