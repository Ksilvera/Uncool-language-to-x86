%%

%class scanner
%unicode
%line
%column
%byaccj

%{
/* For more information, please see the jflex manual
   They have explanation as to why we need a reference
   to a parser object. We also will need a cross-reference
   back to the lexer object.*/

	/* store a reference to the parser object */
	private Parser yyparser;

	/* constructor taking an additional parser */
	public scanner (java.io.Reader r, Parser yyparser) {
		this (r);	
		this.yyparser = yyparser;
	}

	/* return the current line number. We need this
	   because yyline is made private and we don't have
	   a mechanism like extern in C. */
	public int getLine() {
		return yyline;
	}

%}

%%
Bool		{return Parser.BOOL_T;}
class		{return Parser.CLASS_T;}
else		{return Parser.ELSE_T;}
false		{return Parser.FALSE_T;}
fi		{return Parser.FI_T;}
if		{return Parser.IF_T;}
in		{return Parser.IN_T;}
in_int		{return Parser.IN_INT;}
Int		{return Parser.INT_T;}
isvoid		{return Parser.ISVOID_T;}
loop		{return Parser.LOOP_T;}
out_int		{return Parser.OUT_INT;}
out_string	{return Parser.OUT_STRING;}
pool		{return Parser.POOL_T;}
String		{return Parser.STRING_T;}
then		{return Parser.THEN_T;}
true		{return Parser.TRUE_T;}
while		{return Parser.WHILE_T;}
\<		{return Parser.LT;}
\=		{return Parser.EQ;}
\<\=		{return Parser.LE;}
\>\=		{return Parser.GE;}
\>		{return Parser.GT;}
\<\>		{return Parser.NE;}
\<\-		{return Parser.ASSIGN;}
\+		{return (int) yycharat(0); }
\-		{return (int) yycharat(0);  }
\*		{return (int) yycharat(0);  }
\.		{return (int) yycharat(0);  }
\,		{return (int) yycharat(0);  }
\{		{return (int) yycharat(0); }
\}		{return (int) yycharat(0); }
\(		{return (int) yycharat(0); }
\)		{return (int) yycharat(0); }
"["		{return (int) yycharat(0); }
\]		{return (int) yycharat(0); }
\;		{return (int) yycharat(0); }
\:		{return (int) yycharat(0); }
[a-z][A-Za-z0-9_]*	{yyparser.yylval = new ParserVal(yytext()); return Parser.ID;}
[A-Z][A-Za-z0-9_]*	{ return Parser.TYPE;}
[0-9]*		{ yyparser.yylval = new ParserVal(Integer.parseInt(yytext())); return Parser.INT_CONST;}
\"[^\"]*\"	{ yyparser.yylval = new ParserVal(yytext()); return Parser.STRING_CONST;}
\-\-.*		{}
[ \t]		{}	
[\n]		{}
.		{}	

