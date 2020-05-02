

public const COLUMN = "COLUMN";
public const VALUE = "VALUE";

public type Parameter record {
    COLUMN|VALUE parameterType;
    anydata value;
};

public type LogicalOperator AND|OR;

public const AND = "AND";
public const OR = "OR";

type Condition record {
    string operator;
    Parameter right;
    Parameter left;
    LogicalOperator prefixedLogicalOperator?;
};

public type ConditionSet object {
    (Condition|ConditionSet)[] childs = [];
    LogicalOperator prefixedLogicalOperator = AND;

    public function _init(Parameter left, string operator, Parameter right, LogicalOperator lo = AND){
        self.childs.push(<Condition> {
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
    public function and(Parameter left, string operator, Parameter right) returns ConditionSet{

        self.childs.push(<Condition> {
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
    public function or(Parameter left, string operator, Parameter right) returns ConditionSet{
        self.childs.push(<Condition> {
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
    public function andSub(Parameter left, string operator, Parameter right) returns ConditionSet{
        ConditionSet child = new();

        child._init(left, operator, right, AND);

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
    public function orSub(Parameter left, string operator, Parameter right) returns ConditionSet{
        ConditionSet child = new();

        child._init(left, operator, right, OR);

        self.childs.push(child);

        return child;
    }
};

public const LEFT_OUTER = "LEFT_OUTER";
public const RIGHT_OUTER = "RIGHT_OUTER";
public const CROSS = "CROSS";
public const INNER = "INNER";
public type JoinMode LEFT_OUTER | RIGHT_OUTER | CROSS | INNER;

type TableJoin record {
    string tableName;
    string alias;
    ConditionSet conditions?;
};


public type Builder client object  {
    private string tableName;
    private ConditionSet where;

    public function _init(string tableName){
        self.tableName = tableName;
    }

    public function set(){
        
    }

    public function select(){

    }

    public function update(){

    }

    public function insert(){

    }

    public function leftJoin(){
        
    }

    public function crossJoin(){
        
    }

    public function innerJoin(){
        
    }

};

# Converting normal column to an angelina column
# 
# + col - Column name
# + return - Angelina column
public function column(string col) returns Parameter{
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

function serializeParameter(string| Parameter param) returns Parameter {
    if param is Parameter {
        return param;
    } else {
        
        if( param.indexOf(".") != () && param.indexOf(".")== param.lastIndexOf(".")){
            return {
                parameterType: COLUMN,
                value: param
            };
        } else {
            return {
                parameterType: VALUE,
                value: param
            };
        }
    }
}