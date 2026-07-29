const { WindowChrome, TabBar, Banner } = window.AeroSporkDesignSystem_078bd7;

const TABS = [
  { id: 'general', label: 'General', sf: 'gearshape' },
  { id: 'gaps', label: 'Gaps', sf: 'rectangle.split.3x3' },
  { id: 'keys', label: 'Keys', sf: 'keyboard' },
  { id: 'monitors', label: 'Monitors', sf: 'display.2' },
  { id: 'events', label: 'Events', sf: 'bolt' },
  { id: 'rules', label: 'Window Rules', sf: 'macwindow.badge.plus' },
  { id: 'raw', label: 'Raw TOML', sf: 'doc.plaintext' },
];

function SettingsApp({ framed = true, initialTab = 'general', banner = null }) {
  const D = window.AS_DATA;
  const [tab, setTab] = React.useState(initialTab);
  const [settings, setSettings] = React.useState({
    startAtLogin: true, unhide: true, autoMove: true, menuBarIcon: true, dockIcon: false,
    layout: 'tiles', orientation: 'auto', accordionPadding: 30, flatten: true, alternate: true,
    keyMapping: 'qwerty', innerH: 8, innerV: 8, outerTop: 32, outerBottom: 8, outerLeft: 8, outerRight: 8,
  });
  const set = (k, v) => setSettings((s) => ({ ...s, [k]: v }));
  const [bindings, setBindings] = React.useState(D.bindings);
  const [assignments, setAssignments] = React.useState(D.assignments);
  const [rules, setRules] = React.useState(D.rules);
  const [events, setEvents] = React.useState(D.events);
  const [env, setEnv] = React.useState(D.env);
  const [inherit, setInherit] = React.useState(true);
  const [toml, setToml] = React.useState(D.toml);

  const body = (
    <>
      {banner === 'error' && <Banner kind="error">{'Your config was not loaded — AeroSpork is running built-in defaults. Fix the errors below and save; the config reloads by itself.\nline 12: unknown key ‘mods’'}</Banner>}
      <TabBar tabs={TABS} value={tab} onChange={setTab} />
      <div className="tab-body">
        {tab === 'general' && <GeneralTab s={settings} set={set} />}
        {tab === 'gaps' && <GapsTab s={settings} set={set} />}
        {tab === 'keys' && <KeysTab bindings={bindings} setBindings={setBindings} />}
        {tab === 'monitors' && <MonitorsTab monitors={D.monitors} assignments={assignments} setAssignments={setAssignments} />}
        {tab === 'events' && <EventsTab events={events} setEvents={setEvents} env={env} setEnv={setEnv} inherit={inherit} setInherit={setInherit} />}
        {tab === 'rules' && <RulesTab rules={rules} setRules={setRules} />}
        {tab === 'raw' && <RawTomlTab toml={toml} setToml={setToml} original={D.toml} />}
      </div>
    </>
  );

  if (!framed) return <div className="settings-plain">{body}</div>;
  return <WindowChrome width={880} height={620}>{body}</WindowChrome>;
}
Object.assign(window, { SettingsApp, SETTINGS_TABS: TABS });
