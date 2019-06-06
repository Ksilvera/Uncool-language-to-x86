%{
import java.io.*;
import java.util.*;

/*  
All of the below productions that do not have associated 
actions are using the DEFAULT action -- $$ = $1 
*/

%}

%token CLASS_T INT_T BOOL_T STRING_T IN_T 
%token THEN_T ELSE_T FI_T LOOP_T POOL_T
%token ISVOID_T LE LT GT GE NE EQ NOT_T
%token OUT_STRING OUT_INT IN_INT
%token TRUE_T FALSE_T IF_T WHILE_T 
%token <ival> INT_CONST 
%token STRING_CONST
%token TYPE
%token <sval> ID
%token ASSIGN

%right ASSIGN
%nonassoc GE GT NE LT LE EQ
%right UM
%left '+' '-'
%left '*'
%right UC

%type <sval> TYPE STRING_T STRING_CONST INT_T
%type <ival> expr expr_list

%%


program		:	CLASS_T TYPE '{' 
			{start_file(); // enter scope
       
		}
			feature_list '}'
		{ // exit scope 
         
		}
		;

feature_list	:	feature_list feature ';'
		|
		;

feature		:	ID '('        
		{ // enter scope 
        
	start_function($1);
		}
	 		formal_list ')' ':' INT_T 
			'{' expr_list  '}'	
		{ //exit scope
    
	end_function($9);
		}

		|	ID '(' ')' ':' INT_T 
			{if ($1.equals("main")) start_main();
                         else start_function($1);
			 // enter scope
       
	  call();
			}
			'{' expr_list  '}'	
			{	if ($1.equals("main")) end_main($8);
                         else end_function($8);
			 // exit scope
          
			}

 		| 	ID ':' INT_T 
		{ //add symbol table
         	global_table.put($1,$3);
			System.out.println("\t.type\t"+$1+", @object");
			System.out.println("\t.size\t"+$1+", 4");
			System.out.println($1+":\t.long\t0");
			System.out.println("\t.data");
			System.out.println("\t.align 4");
         
		}

 		| 	ID ':' INT_T ASSIGN INT_CONST 
		{ //add symbol table
		global_table.put($1,$5);
       			 System.out.println("\t.type\t"+$1+", @object");
			System.out.println("\t.size\t"+$1+", 4");
			System.out.println($1+":\t.long\t"+lookup($1));
			System.out.println("\t.data");
		}

 		| 	ID ':' STRING_T ASSIGN STRING_CONST 
		{ //add symbol table
        	global_table.put($1,$5);
			System.out.println("c:\t.string "+$5);
			System.out.println("\t.text");
		}

 	 	| 	ID ':' INT_T '[' INT_CONST  ']'  
		{ //add symbol table
        
		}

		;

formal_list	:	formal_list ',' formal
		|	formal
			{
				int offset = 0;
				for(int i = 4; i > 0; i--){
					System.out.println("\tmovl %"+reg.toString(i)+","+offset+"(%rsp)");
					offset+=4;
				}
				for(int i = 6; i < 8; i++){
					System.out.println("\tmovl %"+reg.toString(i)+","+offset+"(%rsp)");
					offset+=4;
				}
				
					
			}
		;

formal		:	ID ':' INT_T 
		{ //add symbol table
        		symbol_table.put($1,para);
			para+=4;
        
		}
		;

expr		:	ID ASSIGN  expr	
			{
				if(symbol_table.containsKey($1))
					System.out.println("\tmovl %"+reg.toString($3)+","+symbol_table.get($1)+"(%rsp)");
				else if(global_table.containsKey($1))
					System.out.println("\tmovl %"+reg.toString($3)+","+$1+"(%rip)");
			}

 	 	|  	ID '[' expr ']'  ASSIGN  expr 	

 		| 	ID '(' ')'
			{
				call();
				System.out.println("\tcall " + $1+"_start");
				System.out.println("\tmovl %eax, %"+reg.toString(reg.getRegister()));
			}	

 		| 	ID '(' actual_list ')'	
			{
				call();
				System.out.println("\tcall " + $1+"_start");
				System.out.println("\tmovl %eax, %"+reg.toString(0));
				for(int i = 7; i > 0; i--){
					if(i != 5)
			  			reg.freeRegister(i);
				}	
			}
		|	IN_INT '(' ')'
			{
				System.out.println("\tmovl $.LC2, %"+reg.toString(4));
				System.out.println("\tmovl $.INPUT, %"+reg.toString(3));
				System.out.println("\tcall __isoc99_scanf");
				return_call();
				int x = reg.getRegister();
				System.out.println("\tmovl .INPUT(%rip),%"+reg.toString(x));
				$$= x;
			}

		|	OUT_STRING '(' STRING_CONST ')'
			{
				System.out.println("\t.data");
				System.out.println(".SS" + count+":\t.string "+ $3);
				System.out.println("\t.text");
				call();
				System.out.println("\tmovl $.SS"+count+", %" + reg.toString(3));
				System.out.println("\tmovl $.LC1, %" + reg.toString(4));
				System.out.println("\tcall printf");
				count += 1;
			}

		|	OUT_STRING '(' ID ')'
			{
				System.out.println("\tmovq $"+$3+", %rsi");
				System.out.println("\tmovq $.LC1, %rdi");
				System.out.println("\tcall printf");
			}

		|	OUT_INT '(' expr ')'
         { 
	    call();
            System.out.println("\tmovl %" + reg.toString($3) + ", %" + reg.toString(3));
            System.out.println("\tmovq $.LC0, "+ "%rdi");
            System.out.println("\tcall printf");
	  }

		|	ID
			{
				String temp;
				Object val;
				int x = reg.getRegister();
				if(symbol_table.containsKey($1)){
					val = symbol_table.get($1);
					temp = "(%rsp)";
				}
				else{
					val = $1;
					temp = "(%rip)";
				}
				System.out.println("\tmovl "+val+ temp+", %"+reg.toString(x));
				$$ = x;
			}

		|	ID '[' expr ']'

 		| 	IF_T expr
			{
				symbol_table.put("else_Label", generateLabel());
				symbol_table.put("exit_Label", generateLabel());
				System.out.println("\tje "+symbol_table.get("else_Label"));
			}
			 THEN_T expr {
				System.out.println("\tmovl %"+reg.toString($5)+", %"+reg.toString(0));
				System.out.println("\tjmp "+symbol_table.get("exit_Label"));
				System.out.println(symbol_table.get("else_Label")+":");
			}
			ELSE_T expr { 
					System.out.println("\tmovl %"+reg.toString($8)+", %"+reg.toString(0));
				}				
			FI_T 
			{
				System.out.println(symbol_table.get("exit_Label")+":");
				symbol_table.remove("else_Label");
				symbol_table.remove("exit_Label");
			}

 		| 	WHILE_T
			{
				symbol_table.put("while_Label",generateLabel());
				symbol_table.put("while_exit",generateLabel());
				System.out.println(symbol_table.get("while_Label")+":");
			} 
			expr
			{
				System.out.println("\tje "+symbol_table.get("while_exit"));
			}
			 LOOP_T expr 
			{
				System.out.println("\tjmp "+symbol_table.get("while_Label"));
			}
			POOL_T 
			{	
				System.out.println(symbol_table.get("while_exit")+":");
				symbol_table.remove("while_Label");
				symbol_table.remove("while_exit");
			}

 		| 	'{'    expr_list '}'	

 		| 	expr  '+' expr
 			{
 				System.out.println("\taddl %" + reg.toString($3) + ", %" + reg.toString($1));
 				$$ = $1;
 				reg.freeRegister($3);
 			}	

 		| 	expr  '-' expr
			{
				System.out.println("\tsubl %" + reg.toString($3) + ", %" + reg.toString($1));
				$$ = $1;
				reg.freeRegister($3);
			}	

 		| 	expr  '*' expr	
			{
				System.out.println("\timul %" + reg.toString($3) + ", %" + reg.toString($1));
				$$ = $1;
				reg.freeRegister($3);	
			}
 		| 	'-' expr  %prec UC	
			{
				System.out.println("\tnegl %" + reg.toString($2));
				$$ = $2; 
			}

 		| 	expr NE expr
			{
				System.out.println("\tcmp %"+reg.toString($3)+", %"+reg.toString($1));
				reg.freeRegister($3);
				System.out.println("\tsetne %al");
				System.out.println("\tmovzbl %al, %"+reg.toString(0));
				System.out.println("\tcmp $0, %"+reg.toString(0));
			}	

 		| 	expr GT expr
			{
				System.out.println("\tcmp %"+reg.toString($3)+", %"+reg.toString($1));
				reg.freeRegister($3);
				System.out.println("\tsetg %al");
				System.out.println("\tmovzbl %al, %"+reg.toString(0));
				System.out.println("\tcmp $0, %"+reg.toString(0));
				
				
			}	

 		| 	expr GE expr	
			{
				System.out.println("\tcmp %"+reg.toString($3)+", %"+reg.toString($1));
				reg.freeRegister($3);
				System.out.println("\tsetge %al");
				System.out.println("\tmovzbl %al, %"+reg.toString(0));
				System.out.println("\tcmp $0, %"+reg.toString(0));
			}

 		| 	expr LT expr
			{
				System.out.println("\tcmp %"+reg.toString($3)+", %"+reg.toString($1));
				reg.freeRegister($3);
				System.out.println("\tsetl %al");
				System.out.println("\tmovzbl %al, %"+reg.toString(0));
				System.out.println("\tcmp $0, %"+reg.toString(0));
			}	

 		| 	expr LE expr	
			{
				System.out.println("\tcmp %"+reg.toString($3)+", %"+reg.toString($1));
				reg.freeRegister($3);
				System.out.println("\tsetle %al");
				System.out.println("\tmovzbl %al, %"+reg.toString(0));
				System.out.println("\tcmp $0, %"+reg.toString(0));
			}

 		| 	expr EQ expr
			{
				System.out.println("\tcmp %"+reg.toString($3)+", %"+reg.toString($1));
				reg.freeRegister($3);
				System.out.println("\tsete %al");
				System.out.println("\tmovzbl %al, %"+reg.toString(0));
				System.out.println("\tcmp $0, %"+reg.toString(0));
			}

		|	'(' expr ')'
			{
				
			}

 		|	TRUE_T 

 		|	FALSE_T 

 		|	INT_CONST 
 			{

 				int k = reg.getRegister();
 				System.out.println("\tmovl $"+ $1 +", %"+reg.toString(k));
 				$$ = k;
 			}
		;

actual_list	:	actual_list ',' expr
			{
				int x = reg.getParam();
				System.out.println("\tmovl %" + reg.toString($3) +", %" + reg.toString(x));
				reg.freeRegister($3); 	
			}
		|	expr
			{	
				int x = reg.getParam();
				System.out.println("\tmovl %" + reg.toString($1) +", %" + reg.toString(x));
				reg.freeRegister($1); 
			}
		;

expr_list	:	expr_list ';' expr
			{
				return_call();
			} 
		|	expr  
			{
				return_call();	
			}
		;


%%

/* Byacc/J expects a member method int yylex(). We need to provide one
   through this mechanism. See the jflex manual for more information. */

	/* reference to the lexer object */
	private scanner lexer;
   
   //Stack for Global
   private HashMap global_table = new HashMap();
   
   //ArrayList for Locals
   private HashMap symbol_table = new HashMap();
	   
   int para = 0;
   int count = 1;
   //Registers
   private Registers reg = new Registers();

	/* interface to the lexer */
	private int yylex() {
		int retVal = -1;
		try {
			retVal = lexer.yylex();
		} catch (IOException e) {
			System.err.println("IO Error:" + e);
		}
		return retVal;
	}
	
	/* error reporting */
	public void yyerror (String error) {
		System.err.println("Error : " + error + " at line " + lexer.getLine());
	}

	/* constructor taking in File Input */
	public Parser (Reader r) {
		lexer = new scanner (r, this);
	}

	public static void main (String [] args) throws IOException {
		Parser yyparser = new Parser(new FileReader(args[0]));
		yyparser.yyparse();
	}
  
int Label=0;
public String generateLabel(){
	String x = "L"+Label;
	Label+=1;
	return x;
}


void
start_file() {
        System.out.print("\t.section\t.rodata\n");
        System.out.print(".LC0:\n\t.string \"%d \"\n");
        System.out.print(".LC1:\n\t.string \"%s \"\n");
        System.out.print(".LC2:\n\t.string \"%d\"\n");
        System.out.print("\t.data\n\t.align\t4\n");
        System.out.print(".INPUT:\n\t.long\t0\n\n");
}

void start_main() {
System.out.print("\t.text\n\t.globl main\n\t.type main,@function\n");
System.out.print("main:\n");
System.out.print("\tpushq %rbp\n");
System.out.print("\tmovq %rsp,%rbp\n");
System.out.print("\tpushq %rbx\n\tpushq %rbp\n\tpushq %r12\n\tpushq %r13\n\tpushq %r14\n\tpushq %r15\n");
System.out.print("\tsubq $128, %rsp\n\n");
}
void end_main(int x){
 System.out.print("\n\tmovl %"+reg.toString(x)+", %eax\n");
 System.out.print("\n\taddq $128, %rsp\n");
 System.out.print("\tpopq %r15 \n\tpopq %r14 \n\tpopq %r13 \n\tpopq %r12 \n\tpopq %rbp \n\tpopq %rbx\n");
System.out.print("\tmovl $0, %eax\n\tpopq %rbp\n\tret\n\n");
}

public void assign(String id, int value, int table) {
		if(table == 1)
			global_table.put (id, value);
		else
			symbol_table.put(id, value);
	}

public int lookup (String id) {
		if(global_table.containsKey(id))
			return (int)global_table.get(id);
		else
			return (int)symbol_table.get(id);
}

void call(){
	System.out.println("\tmovq %rdi, 64(%rsp)");
	    System.out.println("\tmovq %rsi, 72(%rsp)");
	    System.out.println("\tmovq %rdx, 80(%rsp)");
	    System.out.println("\tmovq %rcx, 88(%rsp)");
	    System.out.println("\tmovq %r8, 96(%rsp)");
	    System.out.println("\tmovq %r9, 104(%rsp)");
	    System.out.println("\tmovq %r10, 112(%rsp)");
            System.out.println("\tmovq %r11, 120(%rsp)");
}

void return_call(){
	System.out.println("\tmovq 64(%rsp),%rdi");
	System.out.println("\tmovq 72(%rsp),%rsi");
	System.out.println("\tmovq 80(%rsp),%rdx");
	System.out.println("\tmovq 88(%rsp),%rcx");
	System.out.println("\tmovq 96(%rsp),%r8");
	System.out.println("\tmovq 104(%rsp),%r9");
	System.out.println("\tmovq 112(%rsp),%r10");
	System.out.println("\tmovq 120(%rsp),%r11");
}	

void start_function(String name) {
	String new_name = name +"_start";
	System.out.println("\t.text");
	System.out.println("\t.globl "+new_name);
	System.out.println("\t.type "+new_name+",@function");
	System.out.println(new_name + ":");
	System.out.println("\tpushq %rbp");
	System.out.println("\tmovq %rsp,%rbp");
	System.out.println("\tpushq %rbx\n\tpushq %rbp\n\tpushq %r12\n\tpushq %r13\n\tpushq %r14\n\tpushq %r15");
	System.out.println("\tsubq $128, %rsp\n\n");	
	
}

void end_function(int x) {
	System.out.println("\tmovl %"+reg.toString(x)+", %eax");
	reg.freeRegister(x);
	System.out.println("\taddq $128, %rsp");
	System.out.println("\tpopq %r15\n\tpopq %r14\n\tpopq %r13\n\tpopq %r12\n\tpopq %rbp\n\tpopq %rbx");
	System.out.println("\tpopq %rbp\n\tret\n");
}

public class Registers{
   int available[]; 
   public Registers() { 
      available=new int[14]; 
   }
   
   public int getRegister() {
      for (int i = 8;i<14;i++){
         if (available[i] == 0) {
            available[i] = 1; //1 means is free
            return i;
         }
      }
      for(int i = 0; i < 8; i++){
	if(available[i] == 0 ){
		available[i] = 1;
		return i;
	}
      }
           return 0; //0 is being used
   }
   
   public int getParam(){
     for(int i = 4; i > 0; i--){
	if(available[i] == 0){
	   available[i] = 1;
	   return i;
	}
      }
	for(int i = 6; i < 8; i++){
		if(available[i] == 0){
			available[i] = 1;
			return i;
		}
	}
	return 0;
     
   }
	
   public void freeRegister(int r) {
         available[r] = 0;
    }
    
    public String toString(int x){
         if(x == 0)
            return "ebx";
         else if(x == 1)
            return "ecx";
         else if(x == 2)
            return "edx";
         else if(x == 3)
            return "esi";
         else if(x == 4)
            return "edi";
         else if(x == 5)
            return "ebp";
         else if(x == 6)
         	return "r8d";
         else if(x == 7)
         	return "r9d";
         else if(x == 8)
         	return "r10d";
          else if(x == 9)
         	return "r11d";
         else if(x == 10)
         	return "r12d";
         else if(x == 11)
         	return "r13d";
         else if(x == 12)
         	return "r14d";
         else if(x == 13)
         	return "r15d";
         else
            return "Not Valid";
    }
  }
