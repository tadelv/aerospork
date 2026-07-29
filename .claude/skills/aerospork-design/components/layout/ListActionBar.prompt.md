Use under any editable table (window rules, workspace assignments). Icon-only buttons carry no title, so addHelp/removeHelp must read as labels ("Pin a workspace to a monitor").

~~~jsx
<ListActionBar addHelp="Add a window rule" removeHelp="Remove the selected rule"
  onAdd={addRule} onRemove={selected ? removeRule : null} />
~~~
