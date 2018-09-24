# Foo Library

Description of Foo Library.  
  
**Note:** This is an important note with <kbd>EMPHASIS</kbd>.  
    
Features:  

- Foo
- Bar

## Usage Heading

Within a text string, <var>highlight variables</var> using var tags, and <dfn>highlight code</dfn> using the dfn tags.

### Sub-heading

Put code examples within pre and code tags:</p>

<pre><code>rigLoaderLoadLibrary "Foo"

put "bar" into tArray["bat"]
</code></pre>


## Table Preferences

Use tables where appropriate for long lists of preferences.  

| Preference | Default&nbsp;Value | Options | Description |
| ---- | :-- | :-- | :-- |
| **foo** | Foo | None | Description of foo. |
| **bar** | Bar | bat, bag, or bak | Description of bar. |


## Handler Reference

### rigFooFunction(<var>tParam1</var>, <var>tParam2</var>, <var>tParam3</var>)

Description

Example:  

<pre><code>put FALSE into tFoo
# MY COMMENT
if rigFooFunction(tFoo) &lt;> FALSE then
  # MY CODE HERE . . .

end if
</code></pre>