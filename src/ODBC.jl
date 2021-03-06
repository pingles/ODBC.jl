#TODO
#'Create table' function passing a dataframe
#create test.jl file that has mysql driver and connects to ensembl database
#Asynchronous querying
#Finish consts definitions from C header files
#compare linux, windows, mac header files for differences
#Test that functions work
#Create backend/userfacing functions for ODBC API functions
#read through the 64-bit stuff to really understand if any changes need to be made
#How to deal with Unicode/ANSI function calling?
#Fix LargeFetch function; could be more efficient probably
#Excel, Access driver testing?

module ODBC

using DataFrames

export connect, advancedconnect, query, querymeta, @sql_str, Connection, Metadata, conn, Connections, disconnect, listdrivers, listdsns

import Base.show, Base.connect

include("ODBC_API.jl")

#Metadata type holds metadata related to an executed query resultset
type Metadata
	querystring::String
	cols::Int
	rows::Int
	colnames::Array{ASCIIString}
	coltypes::Array{(String,Int16)}
	colsizes::Array{Int}
	coldigits::Array{Int16}
	colnulls::Array{Int16}
end
show(meta::Metadata) = show(OUTPUT_STREAM,meta)
function show(io::IO,meta::Metadata)
	if meta == null_meta
		print(io,"No metadata")
	else
		println(io,"Resultset metadata for executed query")
		println(io,"------------------------------------")
		println(io,"Columns: $(meta.cols)")
		println(io,"Rows: $(meta.rows)")
		println(io,"Column Names: $(meta.colnames)")
		println(io,"Column Types: $(meta.coltypes)")
		println(io,"Column Sizes: $(meta.colsizes)")
		println(io,"Column Digits: $(meta.coldigits)")
		println(io,"Column Nullable: $(meta.colnulls)")
	end 
end
function show(io::IO,t::Array{Metadata,1})
	for i in t
		show(i)
	end
end
#Connection object that holds information related to each established connection and retrieved resultsets
type Connection
	dsn::String
	number::Int
	dbc_ptr::Ptr{Void}
	stmt_ptr::Ptr{Void}
	resultset::Union(DataFrame,Array{DataFrame,1},Metadata,Array{Metadata,1})
end
function show(io::IO,conn::Connection)
	if conn == null_connection
		print("Null ODBC Connection Object")
	else
		println("ODBC Connection Object")
		println("----------------------")
		println("Connection Data Source: $(conn.dsn)")
		println("$(conn.dsn) Connection Number: $(conn.number)")
		println("Connection pointer: $(conn.dbc_ptr)")
		println("Statement pointer: $(conn.stmt_ptr)")
		if isequal(conn.resultset,null_resultset)
		print("Contains resultset? No")
		else
		print("Contains resultset(s)? Yes (access by referencing the resultset field)")
		end
	end
end

#Global module consts and variables
const null_resultset = DataFrame(0)
const null_connection = Connection("",0,C_NULL,C_NULL,null_resultset)
const null_meta = Metadata("",0,0,ref(ASCIIString),Array((String,Int16),0),ref(Int),ref(Int16),ref(Int16))
env = C_NULL
Connections = ref(Connection) #For managing references to multiple connections
conn = null_connection #Create default connection = null
ret = ""

include("backend.jl")
include("userfacing.jl")

end #ODBC module
