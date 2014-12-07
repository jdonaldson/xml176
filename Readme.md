# txml176

The txml176 library is a variation of the 
[xml176](https://github.com/HxJointForces/xml176) library that is designed to
work with *templated* xml.

## Templated XML 
Templated xml is a special form of xml suited towards replacing attributes and 
PCData with expressions.  The template markers are simple open/closed brackets.
Content inside the bracketed template slots have greatly relaxed character 
restrictions compared to conventional xml standards.  Users may use any
character, including brackets.  However, if they use brackets, they must take 
care to close the brackets that they open, or escape them with a backslash (\).


Templated attibute values:
```xml
<Foo bar={x}/>
```

Templated pcdata:

```xml
<Foo>
   {node_data}
</Foo>
```


