JFLEX=/home/white/JFlex.jar
BYACC=/home/white/bin/byacc

uncool: scanner.java Parser.java 
	javac -classpath "" *.java

Parser.java:	uncool.y
	$(BYACC) -J uncool.y

scanner.java:	uncool.l
	java -jar $(JFLEX)  uncool.l

clean:
	rm -rf *.class scanner.java* Parser.java ParserVal.java
