const COMMANDS = [
  {
    cmd: 'aerospork list-monitors',
    out: [
      ['1 | Built-in Retina Display'],
      ['2 | DELL U2720Q'],
      ['3 | DisplayLink Monitor'],
    ],
  },
  {
    cmd: "aerospork list-monitors --format '%{monitor-fingerprint}'",
    out: [
      ['uuid=BBBBBBBB-0000-4000-8000-000000000002 vendor=0x0610 model=0xA050 serial=0 1728x1117'],
      ['uuid=AAAAAAAA-0000-4000-8000-000000000001 vendor=0x10AC model=0xD0C1 serial=1273 2560x1440'],
      ['uuid=CCCCCCCC-0000-4000-8000-000000000003 vendor= model= serial= 1920x1080', 'dim'],
      ['# the DisplayLink panel reports no EDID — its UUID is the only usable key', 'dim'],
    ],
  },
  {
    cmd: 'aerospork list-workspaces --monitor all',
    out: [['1'], ['2'], ['web']],
  },
  {
    cmd: 'aerospork focus left',
    out: [],
  },
  {
    cmd: 'aerospork layout tiles horizontal vertical',
    out: [],
  },
  {
    cmd: 'aerospork config --config-path',
    out: [['/Users/you/.aerospork.toml']],
  },
  {
    cmd: 'aerospork reload-config --dry-run',
    out: [['config parsed; 0 warnings', 'ok']],
  },
  {
    cmd: 'aerospork --version',
    out: [['aerospork CLI 0.4.1 a91f2c8d'], ['aerospork server 0.4.1 a91f2c8d']],
  },
];

function CliKit() {
  const [ran, setRan] = React.useState([0, 1]);
  const bodyRef = React.useRef(null);
  React.useEffect(() => { if (bodyRef.current) bodyRef.current.scrollTop = bodyRef.current.scrollHeight; }, [ran]);
  return (
    <div className="term">
      <div className="term-bar">
        <span className="tl" style={{ background: '#ff5f57' }} /><span className="tl" style={{ background: '#febc2e' }} /><span className="tl" style={{ background: '#28c840' }} />
        <span style={{ flex: 1, textAlign: 'center', marginRight: 56 }}>you — -zsh — 86×24</span>
      </div>
      <div className="term-body" ref={bodyRef}>
        {ran.map((i, n) => {
          const c = COMMANDS[i];
          return (
            <div key={n}>
              <div><span className="prompt">~ ❯</span> {c.cmd}</div>
              {c.out.map((line, j) => <div key={j} className={line[1] || ''}>{line[0]}</div>)}
              {!c.out.length && <div className="dim">{'\u00a0'}</div>}
            </div>
          );
        })}
        <div><span className="prompt">~ ❯</span> <span style={{ background: '#d7dbe4', color: '#14161c' }}>&nbsp;</span></div>
      </div>
      <div className="picker">
        {COMMANDS.map((c, i) => (
          <button key={i} className={ran[ran.length - 1] === i ? 'on' : ''} onClick={() => setRan([...ran, i])}>
            {c.cmd.replace('aerospork ', '')}
          </button>
        ))}
        <button onClick={() => setRan([])} style={{ marginLeft: 'auto' }}>clear</button>
      </div>
    </div>
  );
}
Object.assign(window, { CliKit });
