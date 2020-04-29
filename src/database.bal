# All about database

enum Mode {
    UPDATE;
    CREATE;
}

type Database {
    string name;
    Mode mode; 
}