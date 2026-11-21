// Chamado pelos fluxos com env MOCK_URL e ACTION (ex.: "reset", "scenario/erro-500", "scenario/erro-500:off").
// Roda dentro do Maestro (GraalJS) — usa a API http do Maestro.
var base = MOCK_URL || 'http://localhost:3000';
var parts = ACTION.split(':');
var path = parts[0] === 'reset' ? '/__mock/reset' : '/__mock/' + parts[0];
var body = parts[1] === 'off' ? JSON.stringify({ active: false }) : '{}';
var res = http.post(base + path, { headers: { 'Content-Type': 'application/json' }, body: body });
if (res.status >= 300) throw new Error('mock ' + path + ' respondeu ' + res.status);
