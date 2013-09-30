source init.tcl
source sqlite.tcl

::tdbc::sqlite create sqlDb -db_file :memory:
sqlDb eval "create table foo (node_id integer not null,data string not null,time timestamp)"
sqlDb eval "INSERT INTO foo (node_id,data,time) VALUES (1,'fluffy',[clock seconds])"
sqlDb eval "INSERT INTO foo (node_id,data,time) VALUES (2,'fluffy',[clock seconds])"

set result {}
sqlDb eval "select node_id,data from foo" values {
    set cols $values(*)
    set row {}
    foreach col $cols {
	lappend row $values($col)
    }
    lappend result $row
}
puts $result
puts [sqlDb query "select node_id,data from foo"]
puts [sqlDb eval "select node_id,data from foo"]
puts [sqlDb query_flat "select node_id,data from foo"]

puts [sqlDb tables]
puts [sqlDb tables foo]

puts [sqlDb columns foo]