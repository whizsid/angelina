

public const COLUMN = "COLUMN";
public const VALUE = "VALUE";

public type Parameter record {
    COLUMN|VALUE parameterType;
    anydata value;
};

type Condition record {
    string operator;
    Parameter right;
    Parameter left;
};

public const AND = "AND";
public const OR = "OR";

public type LogicalOperator AND|OR;


public type ConditionSet object {
    private LogicalOperator LogicalOperator;
    (Condition|ConditionSet)[] childs = [];

    public function _init(Parameter left, string operator, Parameter right){
        self.childs.push(<Condition> {
            left,
            right,
            operator
        });
    }

    public function and(){
        
    }

    public function sub(Parameter left, string operator, Parameter right) returns ConditionSet{
        ConditionSet child = new();

        child._init(left, operator, right);

        self.childs.push(child);

        return child;
    }
};

public const LEFT_OUTER = "LEFT_OUTER";
type TableJoin record {
    string tableName;
    string alias;
    ConditionSet conditions;
};


public type Builder client object  {
    private string tableName;

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

    public function joinTable(){
        
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
        if( param.indexOf(".") !=() && param.indexOf(".")== param.lastIndexOf(".")){
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