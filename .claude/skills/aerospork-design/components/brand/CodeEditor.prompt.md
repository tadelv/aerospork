Use for the raw TOML surface and for any place a config file is shown editable. Always pair with an explicit Apply and a StatusLabel — never auto-apply half-typed TOML.

~~~jsx
<CodeEditor value={toml} onChange={setToml} />
~~~
