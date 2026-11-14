function varargout = gpsTimeConverter(action, varargin)
%GPSTIMECONVERTER  GPS 时间 <-> UTC 时间转换器（单文件 GUI，可直接打包）
%
%   打开图形界面
%       gpsTimeConverter
%
%   命令行 / 脚本接口（便于自检或批处理）
%       r = gpsTimeConverter('gps2utc', week, towOfWeek)
%       r = gpsTimeConverter('gps2utc', gpsSeconds)
%       r = gpsTimeConverter('utc2gps', '2026-11-06 00:00:00')
%       T = gpsTimeConverter('batch', records [, mode])
%       T = gpsTimeConverter('batch', 'input.txt')
%       gpsTimeConverter('export', T, 'result.csv')
%       gpsTimeConverter('batchdialog')     % 打开批量转换对话框
%       T = gpsTimeConverter('leaptable')
%
%   批量转换 records 可为：
%       N×2 数值矩阵（第 1 列 GPS 周、第 2 列周内秒）
%       数值向量（GPS 累计秒）
%       字符元胞数组 / 字符串数组（每行一条记录）
%       .txt / .csv 文件路径（UTF-8 或系统默认编码）
%   mode 可省略（auto 逐行识别），或指定 'week' / 'sec' / 'utc'。
%   返回表列：Index / Input / UTC / Beijing / GPSWeek / GPSTow / GPSSec /
%             GPS_UTC / Note（Note 记录失败原因）。
%
%   换算约定
%       GPS 时起点为 1980-01-06 00:00:00 UTC，GPS 时不含闰秒；
%       UTC = GPS - (GPS-UTC 累计闰秒差)，2017-01-01 起为 18 s。
%       返回结构体字段：gpsSeconds / gpsWeek / gpsTow / leapSeconds /
%       utcText / beijingText / isLeapSecond / julianDate / dowName
%
%   打包为独立程序
%       deploytool -> Application Compiler -> 主文件选 gpsTimeConverter.m
%       或命令行：mcc -m gpsTimeConverter.m -o GPSTimeConverter
%       目标机需安装对应版本 MATLAB Runtime；本程序不依赖任何工具箱。

if nargin >= 1
    if ~(ischar(action) || (isstring(action) && isscalar(action)))
        error('第一个参数必须是命令字符串，例如 ''gps2utc''。');
    end
    [varargout{1:nargout}] = gpsCli(char(action), varargin{:});
    return
end

fig = buildGui();
if nargout >= 1
    varargout{1} = fig;
end
end

% ======================================================================
%  图形界面
% ======================================================================
function fig = buildGui()
h = struct();

h.fig = uifigure('Name', 'GPS 时间 <-> UTC 时间转换器', ...
    'Position', [100 100 780 590], ...
    'Color', [0.96 0.96 0.97], ...
    'Resize', 'on');
try   % 居中显示
    sc = get(groot, 'ScreenSize');
    p = h.fig.Position;
    h.fig.Position = [max(20, (sc(3) - p(3)) / 2), ...
                      max(20, (sc(4) - p(4)) / 2), p(3), p(4)];
catch
end

uilabel(h.fig, 'Text', 'GPS 时间 <-> UTC 时间转换器', ...
    'Position', [26 540 600 34], 'FontSize', 20, 'FontWeight', 'bold', ...
    'FontColor', [0.10 0.25 0.45]);
uilabel(h.fig, 'Text', ['GPS 起点 1980-01-06 00:00:00 UTC  |  GPS 时不含闰秒  |  ' ...
    '当前 GPS-UTC = 18 s'], ...
    'Position', [28 514 730 22], 'FontSize', 11, 'FontColor', [0.35 0.35 0.35]);

pIn = uipanel(h.fig, 'Title', '输入', 'FontSize', 12, ...
    'Position', [24 334 732 172], 'BackgroundColor', [0.96 0.96 0.97]);

% ---- 转换方向 ----
uilabel(pIn, 'Text', '转换方向', 'Position', [14 110 64 22], 'FontSize', 12);
h.mode = uidropdown(pIn, ...
    'Items', {'GPS 周 + 周内秒 -> UTC', 'GPS 累计秒 -> UTC', 'UTC -> GPS 周 / 周内秒'}, ...
    'Position', [82 108 300 26], 'Tag', 'modeDrop', ...
    'ValueChangedFcn', @(src, evt) updateMode());

% ---- GPS 周 / 周内秒 / 累计秒 ----
uilabel(pIn, 'Text', 'GPS 周', 'Position', [14 72 56 22], 'FontSize', 12);
h.week = uieditfield(pIn, 'text', 'Position', [72 70 100 26], ...
    'Tag', 'weekEdit', 'ValueChangedFcn', @(src, evt) onFieldCommit(src));
uilabel(pIn, 'Text', '周内秒', 'Position', [184 72 56 22], 'FontSize', 12);
h.tow = uieditfield(pIn, 'text', 'Position', [242 70 130 26], ...
    'Tag', 'towEdit', 'ValueChangedFcn', @(src, evt) onFieldCommit(src));
uilabel(pIn, 'Text', 'GPS 累计秒', 'Position', [384 72 86 22], 'FontSize', 12);
h.sec = uieditfield(pIn, 'text', 'Position', [474 70 160 26], ...
    'Tag', 'secEdit', 'ValueChangedFcn', @(src, evt) onFieldCommit(src));

% ---- UTC 时间 ----
uilabel(pIn, 'Text', 'UTC 时间', 'Position', [14 34 56 22], 'FontSize', 12);
h.utc = uieditfield(pIn, 'text', 'Position', [72 32 440 26], ...
    'Tag', 'utcEdit', 'ValueChangedFcn', @(src, evt) onFieldCommit(src));
h.nowBtn = uibutton(pIn, 'Text', '现在 (UTC)', 'Position', [522 31 100 28], ...
    'Tag', 'nowBtn', 'ButtonPushedFcn', @(src, evt) fillNow());

uilabel(pIn, 'Text', ['时间格式：2026-11-06 00:00:00（可带 .SSS 毫秒）；' ...
    '也支持 2026/11/06、2026年11月6日 8:30'], ...
    'Position', [14 6 706 20], 'FontSize', 10.5, 'FontColor', [0.45 0.45 0.45]);

% ---- 操作按钮 ----
h.convBtn = uibutton(h.fig, 'Text', '开始转换', 'Position', [24 286 120 36], ...
    'Tag', 'convBtn', 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.15 0.42 0.72], 'FontColor', [1 1 1], ...
    'ButtonPushedFcn', @(src, evt) doConvert());
uibutton(h.fig, 'Text', '复制结果', 'Position', [152 288 110 32], ...
    'Tag', 'copyBtn', 'ButtonPushedFcn', @(src, evt) copyResult());
uibutton(h.fig, 'Text', '闰秒表', 'Position', [270 288 96 32], ...
    'Tag', 'leapBtn', 'ButtonPushedFcn', @(src, evt) showLeaps());
uibutton(h.fig, 'Text', '清空', 'Position', [374 288 80 32], ...
    'Tag', 'clearBtn', 'ButtonPushedFcn', @(src, evt) clearAll());
uibutton(h.fig, 'Text', '批量转换', 'Position', [462 288 100 32], ...
    'Tag', 'batchBtn', 'ButtonPushedFcn', @(src, evt) batchDialog(h.fig));
h.status = uilabel(h.fig, 'Text', '就绪', 'Position', [570 292 186 24], ...
    'Tag', 'statusLabel', 'HorizontalAlignment', 'right', ...
    'FontColor', [0.35 0.35 0.35]);

% ---- 结果 ----
uilabel(h.fig, 'Text', '转换结果', 'Position', [26 256 100 22], ...
    'FontSize', 12, 'FontWeight', 'bold');
h.out = uitextarea(h.fig, 'Position', [24 24 732 226], 'Editable', 'off', ...
    'Tag', 'outText', 'FontSize', 13, 'Value', {'（尚未转换）'});

% 初始化：填入当前时间并演示一次转换
updateMode();
fillAllFields();
doConvert();

fig = h.fig;

% ------------------------------------------------------------------
%  嵌套回调
% ------------------------------------------------------------------
    function updateMode()
        m = h.mode.Value;
        useWk  = strcmp(m, 'GPS 周 + 周内秒 -> UTC');
        useSec = strcmp(m, 'GPS 累计秒 -> UTC');
        useUtc = ~useWk && ~useSec;
        toggle(h.week, useWk);
        toggle(h.tow,  useWk);
        toggle(h.sec,  useSec);
        toggle(h.utc,  useUtc);
        toggle(h.nowBtn, useUtc);
    end

    function toggle(comp, tf)
        if tf
            comp.Enable = 'on';
        else
            comp.Enable = 'off';
        end
    end

    function onFieldCommit(src)
        % 在某个输入框里按回车时，自动切到对应方向并转换
        if src == h.week || src == h.tow
            h.mode.Value = 'GPS 周 + 周内秒 -> UTC';
        elseif src == h.sec
            h.mode.Value = 'GPS 累计秒 -> UTC';
        else
            h.mode.Value = 'UTC -> GPS 周 / 周内秒';
        end
        updateMode();
        doConvert();
    end

    function doConvert()
        try
            m = h.mode.Value;
            if strcmp(m, 'GPS 周 + 周内秒 -> UTC')
                wk  = str2double(strtrim(h.week.Value));
                tow = str2double(strtrim(h.tow.Value));
                if isnan(wk) || isnan(tow)
                    error('GPS 周与周内秒必须是数值。');
                end
                if wk < 0 || tow < 0 || tow >= 604800
                    error('GPS 周应不小于 0，周内秒应在 0 ~ 604800 之间（不含 604800）。');
                end
                r = gps2utc(wk * 604800 + tow);
            elseif strcmp(m, 'GPS 累计秒 -> UTC')
                g = str2double(strtrim(h.sec.Value));
                if isnan(g)
                    error('GPS 累计秒必须是数值。');
                end
                r = gps2utc(g);
            else
                r = utc2gps(h.utc.Value);
            end
            h.out.Value = formatResult(r);
            h.status.Text = ['转换完成  ' char(datetime('now'), 'HH:mm:ss')];
            h.status.FontColor = [0.12 0.45 0.20];
        catch err
            h.status.Text = '输入有误，请检查';
            h.status.FontColor = [0.75 0.15 0.15];
            try
                uialert(h.fig, err.message, '转换失败', 'Icon', 'error');
            catch
                errordlg(err.message, '转换失败');
            end
        end
    end

    function fillAllFields()
        % 用当前 UTC 时间填充全部输入框，便于一键试算
        dt = datetime('now', 'TimeZone', 'UTC');
        dt.TimeZone = '';
        dt.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
        h.utc.Value = char(dt);

        r = utc2gps(char(dt));
        t = round(r.gpsSeconds * 1000) / 1000;
        wk = floor(t / 604800);
        tow = t - wk * 604800;
        if tow >= 604800
            wk = wk + 1;
            tow = 0;
        end
        h.week.Value = sprintf('%d', wk);
        h.tow.Value  = sprintf('%.3f', tow);
        h.sec.Value  = sprintf('%.3f', t);
    end

    function fillNow()
        fillAllFields();
        h.mode.Value = 'UTC -> GPS 周 / 周内秒';
        updateMode();
        doConvert();
    end

    function copyResult()
        v = h.out.Value;
        if ischar(v)
            v = {v};
        elseif isstring(v)
            v = cellstr(v);
        end
        try
            clipboard('copy', strjoin(v, sprintf('\n')));
            h.status.Text = '结果已复制到剪贴板';
            h.status.FontColor = [0.12 0.45 0.20];
        catch
            try
                uialert(h.fig, '无法访问系统剪贴板，请手动选中文本复制。', '提示');
            catch
            end
        end
    end

    function showLeaps()
        S = leapTable();
        c = {'GPS-UTC 闰秒表（生效日起累计值，UTC = GPS - 累计值）', ''};
        for i = 1:numel(S.leap)
            c{end+1} = sprintf('%04d-%02d-%02d      GPS-UTC = %2d s', ...
                S.utcDate(i, 1), S.utcDate(i, 2), S.utcDate(i, 3), S.leap(i)); %#ok<AGROW>
        end
        c{end+1} = '';
        c{end+1} = '若 IERS 公布新的闰秒，在 gpsTimeConverter.m 内 leapTable 的 utcDate 末尾追加日期即可。';
        h.out.Value = c;
        h.status.Text = '已显示闰秒表';
        h.status.FontColor = [0.35 0.35 0.35];
    end

    function clearAll()
        h.week.Value = '';
        h.tow.Value  = '';
        h.sec.Value  = '';
        h.utc.Value  = '';
        h.out.Value  = {'（已清空）'};
        h.status.Text = '已清空';
        h.status.FontColor = [0.35 0.35 0.35];
    end
end

% ======================================================================
%  命令行接口
% ======================================================================
function out = gpsCli(action, varargin)
switch lower(action)
    case 'gps2utc'
        if numel(varargin) == 2
            out = gps2utc(varargin{1} * 604800 + varargin{2});
        elseif numel(varargin) == 1
            out = gps2utc(varargin{1});
        else
            error('用法：gpsTimeConverter(''gps2utc'', week, tow) 或 (''gps2utc'', seconds)。');
        end
    case 'utc2gps'
        if numel(varargin) ~= 1
            error('用法：gpsTimeConverter(''utc2gps'', ''2026-11-06 00:00:00'')。');
        end
        out = utc2gps(varargin{1});
    case 'batch'
        if isempty(varargin)
            error(['用法：gpsTimeConverter(''batch'', records [, mode])；' ...
                'records 可为 N×2 数值、数值向量、字符元胞/字符串数组或文本文件路径。']);
        end
        records = varargin{1};
        mode = 'auto';
        if numel(varargin) >= 2
            mode = varargin{2};
        end
        if (ischar(records) || (isstring(records) && isscalar(records)))
            p = char(records);
            if exist(p, 'file') == 2
                records = readInputLines(p);
            end
        end
        out = batchConvert(records, mode);
    case 'batchdialog'
        out = batchDialog();
    case 'export'
        if numel(varargin) < 2
            error('用法：gpsTimeConverter(''export'', T, ''result.csv'')。');
        end
        exportBatchTable(varargin{1}, char(varargin{2}));
        out = [];
    case 'leaptable'
        S = leapTable();
        out = table(datetime(S.utcDate), S.leap, ...
            'VariableNames', {'UTC_Date', 'GPS_minus_UTC'});
    otherwise
        error('未知命令：%s（可用：gps2utc / utc2gps / leaptable）', action);
end
end

% ======================================================================
%  核心换算
% ======================================================================
function S = leapTable()
% GPS-UTC 闰秒表：日期为闰秒生效的 UTC 日期（00:00:00），累计值即 GPS-UTC
S.epoch = datetime(1980, 1, 6, 0, 0, 0);
S.epochDatenum = datenum(1980, 1, 6, 0, 0, 0);
S.utcDate = [ ...
    1981 7 1; 1982 7 1; 1983 7 1; 1985 7 1; 1988 1 1; 1990 1 1; ...
    1991 1 1; 1992 7 1; 1993 7 1; 1994 7 1; 1996 1 1; 1997 7 1; ...
    1999 1 1; 2006 1 1; 2009 1 1; 2012 7 1; 2015 7 1; 2017 1 1];
S.leap = (1:size(S.utcDate, 1))';
% 闰秒生效时刻对应的“朴素秒数”（不含闰秒的连续秒）
S.naive = round((datenum(S.utcDate(:, 1), S.utcDate(:, 2), S.utcDate(:, 3)) ...
    - S.epochDatenum) * 86400);
% 该次闰秒结束后对应的 GPS 秒数
S.threshold = S.naive + S.leap;
end

function r = gps2utc(gpsSec)
% GPS 秒（含周内秒的累计值）-> UTC
S = leapTable();
if ~(isnumeric(gpsSec) && isreal(gpsSec) && isscalar(gpsSec) && isfinite(gpsSec))
    error('GPS 时间必须为有限实数标量。');
end

L = 0;
isLeap = false;
frac = 0;
hit = 0;
for i = 1:numel(S.leap)
    if gpsSec >= S.threshold(i)
        L = S.leap(i);
    elseif gpsSec >= S.threshold(i) - 1
        % 落在第 i 次闰秒（UTC 23:59:60）之内
        hit = i;
        isLeap = true;
        frac = gpsSec - (S.threshold(i) - 1);
        L = S.leap(i) - 1;
        break
    end
end

if isLeap
    d = S.utcDate(hit, :);
    day = datetime(d(1), d(2), d(3)) - days(1);      % 闰秒所在日（前一日）
    dt = day + hours(23) + minutes(59) + seconds(59 + frac);
    sub = floor(frac * 1000 + 1e-9);
    utcText = sprintf('%04d-%02d-%02d 23:59:60.%03d', ...
        day.Year, day.Month, day.Day, sub);
    bj = dt + hours(8);
    bjText = sprintf('%04d-%02d-%02d %02d:%02d:60.%03d', ...
        bj.Year, bj.Month, bj.Day, bj.Hour, bj.Minute, sub);
else
    u = gpsSec - L;
    dt = S.epoch + milliseconds(round(u * 1000));   % 统一到毫秒，避免四舍五入成 :60
    utcText = fmtDateTime(dt);
    bjText = fmtDateTime(dt + hours(8));
end

r = packResult(gpsSec, L, dt, utcText, bjText, isLeap);
end

function r = utc2gps(userInput)
% UTC（文本或 datetime）-> GPS 周 / 周内秒 / 累计秒
S = leapTable();
[dt, isLeap, frac] = parseUtcInput(userInput);

n = seconds(dt - S.epoch);      % 自起点的“朴素秒数”（未加闰秒）

L = 0;
for i = 1:numel(S.leap)
    if n >= S.naive(i)
        L = S.leap(i);
    end
end

sub = floor(frac * 1000 + 1e-9);
if isLeap
    nxt = dateshift(dt, 'start', 'day') + days(1);
    idx = find(S.utcDate(:, 1) == nxt.Year & ...
               S.utcDate(:, 2) == nxt.Month & ...
               S.utcDate(:, 3) == nxt.Day, 1);
    if isempty(idx)
        error('输入的 23:59:60 所在日期不存在闰秒，请核对日期。');
    end
    L = S.leap(idx);
    gpsSec = n + L;
    utcText = sprintf('%04d-%02d-%02d 23:59:60.%03d', ...
        dt.Year, dt.Month, dt.Day, sub);
    bj = dt + hours(8);
    bjText = sprintf('%04d-%02d-%02d %02d:%02d:60.%03d', ...
        bj.Year, bj.Month, bj.Day, bj.Hour, bj.Minute, sub);
else
    gpsSec = n + L;
    utcText = fmtDateTime(dt);
    bjText = fmtDateTime(dt + hours(8));
end

r = packResult(gpsSec, L, dt, utcText, bjText, isLeap);
end

function r = packResult(gpsSec, L, dt, utcText, bjText, isLeap)
r = struct();
r.gpsSeconds   = gpsSec;
r.gpsWeek      = floor(gpsSec / 604800);
r.gpsTow       = gpsSec - r.gpsWeek * 604800;
r.leapSeconds  = L;
r.isLeapSecond = isLeap;
r.utcText      = utcText;
r.beijingText  = bjText;
r.utc          = dt;
r.julianDate   = datenum(dt) + 1721058.5;
names = {'周日', '周一', '周二', '周三', '周四', '周五', '周六'};
dow = mod(floor(r.gpsTow / 86400), 7);   % GPS 周从周日 00:00 起算
r.dowIndex = dow;
r.dowName  = names{dow + 1};
end

function [dt, isLeap, frac] = parseUtcInput(x)
% 解析 UTC 输入；支持 ...23:59:60[.fff] 闰秒写法
isLeap = false;
frac = 0;

if isdatetime(x)
    dt = x;
    if numel(dt) ~= 1
        error('时间必须是标量。');
    end
    if ~isempty(dt.TimeZone)
        dt = datetime(dt, 'TimeZone', 'UTC');
        dt.TimeZone = '';
    end
    return
end

if isstring(x) && isscalar(x)
    x = char(x);
end
if ~ischar(x)
    error('时间输入必须为文本或 datetime。');
end

s = strtrim(x);
tok = regexp(s, '^(.*?)(\d{1,2}:\d{1,2}):60(\.\d+)?$', 'tokens', 'once');
if ~isempty(tok)
    isLeap = true;
    if ~isempty(tok{3})
        frac = str2double(tok{3});
    end
    s = [tok{1}, tok{2}, ':59', tok{3}];
end

dt = parseDateTime(s);
end

function dt = parseDateTime(s)
% 兼容多种书写格式，统一为无时区的 datetime（毫秒精度）
s = strtrim(s);
s = regexprep(s, '(\d{4})年(\d{1,2})月(\d{1,2})日', '$1-$2-$3');
s = regexprep(s, '\s+', ' ');
if ~isempty(regexp(s, '\dT\d', 'once'))
    s = strrep(s, 'T', ' ');
end

fmts = {'yyyy-MM-dd HH:mm:ss.SSS', 'yyyy-MM-dd HH:mm:ss', ...
        'yyyy/MM/dd HH:mm:ss.SSS', 'yyyy/MM/dd HH:mm:ss', ...
        'yyyy-MM-dd HH:mm', 'yyyy/MM/dd HH:mm', ...
        'yyyy-M-d H:m:s', 'yyyy-M-d H:m', ...
        'yyyy/M/d H:m:s', 'yyyy/M/d H:m'};
dt = NaT;
for i = 1:numel(fmts)
    try
        dt = datetime(s, 'InputFormat', fmts{i});
        break
    catch
        dt = NaT;
    end
end
if isnat(dt)
    try
        dt = datetime(s);          % 交给 MATLAB 自动识别（ISO 8601 等）
    catch
        error('无法识别的时间格式：“%s”。示例：2026-11-06 00:00:00', s);
    end
end
if isnat(dt)
    error('无法识别的时间格式：“%s”。示例：2026-11-06 00:00:00', s);
end
if ~isempty(dt.TimeZone)
    dt = datetime(dt, 'TimeZone', 'UTC');
    dt.TimeZone = '';
end
end

function s = fmtDateTime(dt)
% 以毫秒精度格式化，规避 59.9996 被 %f 四舍五入成 60.000 的问题
d = dateshift(dt, 'start', 'day');
ms = floor(seconds(dt - d) * 1000 + 1e-4);
hh = floor(ms / 3600000);
mm = floor(mod(ms, 3600000) / 60000);
ss = mod(ms, 60000) / 1000;
s = sprintf('%04d-%02d-%02d %02d:%02d:%06.3f', ...
    dt.Year, dt.Month, dt.Day, hh, mm, ss);
end

function lines = formatResult(r)
lines = { ...
    sprintf('UTC 时间          ：%s', r.utcText), ...
    sprintf('北京时间 (UTC+8)  ：%s', r.beijingText), ...
    sprintf('GPS 周 / 周内秒   ：%d / %.3f s', r.gpsWeek, r.gpsTow), ...
    sprintf('GPS 累计秒        ：%.3f s', r.gpsSeconds), ...
    sprintf('GPS-UTC 闰秒差    ：%d s', r.leapSeconds), ...
    sprintf('周内第几天        ：第 %d 天（%s）', floor(r.gpsTow / 86400) + 1, r.dowName), ...
    sprintf('儒略日 (UTC)      ：%.6f', r.julianDate)};
if r.isLeapSecond
    lines{end+1} = '说明：该 GPS 时刻对应 UTC 闰秒 23:59:60（当日第 86401 秒）。';
    lines{end+1} = '      此时 GPS-UTC 仍为闰秒前的值，下一秒才递增。';
end
end

% ======================================================================
%  批量转换核心
% ======================================================================
function T = batchConvert(records, mode)
%BATCHCONVERT 批量把 GPS 时间换算成 UTC（失败行不中断，错误写入 Note）
if nargin < 2 || isempty(mode)
    mode = 'auto';
end
mode = lower(char(mode));

if isnumeric(records)
    if isempty(records)
        records = zeros(0, 1);
    end
    if size(records, 2) == 2
        mode = 'week';
        n = size(records, 1);
        inText = cell(n, 1);
        for i = 1:n
            inText{i} = sprintf('%d, %.3f', records(i, 1), records(i, 2));
        end
    else
        records = records(:);
        mode = 'sec';
        n = numel(records);
        inText = cell(n, 1);
        for i = 1:n
            inText{i} = sprintf('%.3f', records(i));
        end
    end
else
    if isstring(records)
        records = cellstr(records);
    elseif ischar(records)
        records = {records};
    end
    if ~iscell(records)
        error('批量输入应为数值矩阵、数值向量、字符元胞/字符串数组或文本文件。');
    end

    records = records(:);
    tmp = cell(numel(records), 1);
    k = 0;
    for i = 1:numel(records)
        s = strtrim(char(records{i}));
        if isempty(s) || s(1) == '#'
            continue      % 空行与 # 注释
        end
        k = k + 1;
        tmp{k} = s;
    end
    inText = tmp(1:k);

    % 首行若不含任何数字，视为表头
    if ~isempty(inText) && isempty(regexp(inText{1}, '\d', 'once'))
        inText(1) = [];
    end
    n = numel(inText);
end

utcText = repmat({''}, n, 1);
bjText  = repmat({''}, n, 1);
note    = repmat({''}, n, 1);
gpsWeek = nan(n, 1);
gpsTow  = nan(n, 1);
gpsSec  = nan(n, 1);
leap    = nan(n, 1);

for i = 1:n
    try
        r = convertBatchLine(inText{i}, mode);
        utcText{i} = r.utcText;
        bjText{i}  = r.beijingText;
        gpsWeek(i) = r.gpsWeek;
        gpsTow(i)  = r.gpsTow;
        gpsSec(i)  = r.gpsSeconds;
        leap(i)    = r.leapSeconds;
        if r.isLeapSecond
            note{i} = '闰秒 23:59:60';
        end
    catch err
        note{i} = err.message;
    end
end

T = table((1:n)', inText, utcText, bjText, gpsWeek, gpsTow, gpsSec, leap, note, ...
    'VariableNames', {'Index', 'Input', 'UTC', 'Beijing', 'GPSWeek', ...
                      'GPSTow', 'GPSSec', 'GPS_UTC', 'Note'});
end

function r = convertBatchLine(s, mode)
if strcmp(mode, 'auto')
    [k, a, b] = classifyBatchLine(s);
    if strcmp(k, 'week')
        r = gps2utc(a * 604800 + b);
    elseif strcmp(k, 'sec')
        r = gps2utc(a);
    else
        r = utc2gps(s);
    end
    return
end

switch mode
    case {'week', 'w'}
        nums = str2double(splitBatchTokens(s));
        if numel(nums) < 2 || isnan(nums(1)) || isnan(nums(2))
            error('格式应为“GPS 周, 周内秒”：%s', s);
        end
        r = gps2utc(nums(1) * 604800 + nums(2));
    case {'sec', 'seconds', 'gps'}
        v = str2double(strtrim(s));
        if isnan(v)
            error('格式应为 GPS 累计秒：%s', s);
        end
        r = gps2utc(v);
    otherwise
        r = utc2gps(s);
end
end

function [kind, a, b] = classifyBatchLine(s)
a = NaN;
b = NaN;
if ~isempty(regexp(s, '\d{4}\s*[-/.年]\s*\d{1,2}', 'once'))
    kind = 'utc';
    return
end
tok = splitBatchTokens(s);
num = str2double(tok);
if numel(tok) >= 2 && ~isnan(num(1)) && ~isnan(num(2))
    kind = 'week';
    a = num(1);
    b = num(2);
elseif numel(tok) == 1 && ~isnan(num(1))
    kind = 'sec';
    a = num(1);
else
    kind = 'utc';
end
end

function tok = splitBatchTokens(s)
tok = regexp(strtrim(s), '[,\s;]+', 'split');
tok = tok(~cellfun(@isempty, tok));
end

function lines = readInputLines(path)
%READINPUTLINES 读取文本文件为行元胞（去掉 BOM 与空行）
txt = fileread(path);
if ~isempty(txt) && double(txt(1)) == 65279
    txt = txt(2:end);
end
lines = regexp(txt, '\r\n|\n|\r', 'split')';
lines = strtrim(lines);
lines = lines(~cellfun(@isempty, lines));
end

function lines = previewBatch(T, maxRows)
%PREVIEWBATCH 生成批量结果的文本预览
if nargin < 2 || isempty(maxRows)
    maxRows = 200;
end
n = height(T);
bad = sum(isnan(T.GPSWeek));
lines = {sprintf('共 %d 条，成功 %d 条，失败 %d 条', n, n - bad, bad), ...
         '  序号  UTC 时间                 GPS 周 / 周内秒            GPS 累计秒'};
m = min(n, maxRows);
for i = 1:m
    if isnan(T.GPSWeek(i))
        lines{end+1} = sprintf('%5d  %s  ->  失败：%s', i, T.Input{i}, T.Note{i}); %#ok<AGROW>
    else
        extra = '';
        if ~isempty(T.Note{i})
            extra = ['  [' T.Note{i} ']'];
        end
        lines{end+1} = sprintf('%5d  %-23s  W%-4d / %12.3f  %16.3f%s', ...
            i, T.UTC{i}, T.GPSWeek(i), T.GPSTow(i), T.GPSSec(i), extra); %#ok<AGROW>
    end
end
if n > m
    lines{end+1} = sprintf('...（仅预览前 %d 条，导出可得全部 %d 条）', m, n);
end
end

function exportBatchTable(T, path)
%EXPORTBATCHTABLE 导出批量结果（.csv 带 UTF-8 BOM，.xlsx 用 writetable）
if ~istable(T) || ~all(ismember({'Index', 'Input', 'UTC', 'Beijing', ...
        'GPSWeek', 'GPSTow', 'GPSSec', 'GPS_UTC', 'Note'}, T.Properties.VariableNames))
    error('导出数据必须是 gpsTimeConverter(''batch'', ...) 返回的表。');
end
if isempty(path)
    error('请指定导出文件路径（.csv 或 .xlsx）。');
end

[~, ~, ext] = fileparts(path);
cn = {'序号', '输入', 'UTC时间', '北京时间', 'GPS周', '周内秒', ...
      'GPS累计秒', 'GPS-UTC闰秒', '备注'};

if strcmpi(ext, '.csv')
    writeBatchCsv(T, cn, path);
elseif strcmpi(ext, '.xlsx') || strcmpi(ext, '.xls')
    T2 = table(T.Index, T.Input, T.UTC, T.Beijing, T.GPSWeek, T.GPSTow, ...
        T.GPSSec, T.GPS_UTC, T.Note, 'VariableNames', cn);
    writetable(T2, path, 'Sheet', 1);
else
    error('导出格式仅支持 .csv 或 .xlsx：%s', path);
end
end

function writeBatchCsv(T, header, path)
fid = fopen(path, 'w', 'n', 'UTF-8');
if fid < 0
    error('无法写入文件：%s', path);
end
cleaner = onCleanup(@() fclose(fid));

fprintf(fid, '%s', char(65279));      % UTF-8 BOM，避免 Excel 打开乱码
fprintf(fid, '%s\n', strjoin(cellfun(@csvEsc, header, 'UniformOutput', false), ','));

for i = 1:height(T)
    row = cell(1, 9);
    row{1} = sprintf('%d', T.Index(i));
    row{2} = T.Input{i};
    row{3} = T.UTC{i};
    row{4} = T.Beijing{i};
    if isnan(T.GPSWeek(i))
        row{5} = '';
        row{6} = '';
        row{7} = '';
        row{8} = '';
    else
        row{5} = sprintf('%d', T.GPSWeek(i));
        row{6} = sprintf('%.3f', T.GPSTow(i));
        row{7} = sprintf('%.3f', T.GPSSec(i));
        row{8} = sprintf('%d', T.GPS_UTC(i));
    end
    row{9} = T.Note{i};
    row = cellfun(@csvEsc, row, 'UniformOutput', false);
    fprintf(fid, '%s\n', strjoin(row, ','));
end
end

function s = csvEsc(s)
s = char(s);
s = strrep(s, '"', '""');
if ~isempty(regexp(s, '[,"\r\n]', 'once'))
    s = ['"' s '"'];
end
end

% ======================================================================
%  批量转换对话框
% ======================================================================
function fig = batchDialog(parentFig)
if nargin < 1
    parentFig = [];
end

try   % 模态窗口，避免同时操作主界面
    hb.fig = uifigure('Name', '批量转换', 'Color', [0.96 0.96 0.97], ...
        'Position', [160 120 860 660], 'WindowStyle', 'modal');
catch
    hb.fig = uifigure('Name', '批量转换', 'Color', [0.96 0.96 0.97], ...
        'Position', [160 120 860 660]);
end
hb.T = [];

try
    sc = get(groot, 'ScreenSize');
    p = hb.fig.Position;
    hb.fig.Position = [max(20, min(p(1), sc(3) - p(3) - 20)), ...
                       max(20, min(p(2), sc(4) - p(4) - 60)), p(3), p(4)];
catch
end

uilabel(hb.fig, 'Text', '批量转换', 'Position', [22 612 300 28], ...
    'FontSize', 17, 'FontWeight', 'bold', 'FontColor', [0.10 0.25 0.45]);
uilabel(hb.fig, 'Text', '输入格式', 'Position', [22 578 64 22], 'FontSize', 12);
hb.mode = uidropdown(hb.fig, ...
    'Items', {'自动识别（推荐）', 'GPS 周 + 周内秒', 'GPS 累计秒', 'UTC 时间'}, ...
    'Position', [88 576 240 26], 'Tag', 'batchMode');
uibutton(hb.fig, 'Text', '载入文件…', 'Position', [344 575 110 28], ...
    'Tag', 'batchLoad', 'ButtonPushedFcn', @(src, evt) loadFile());

uilabel(hb.fig, 'Text', '每行一条记录：2443, 432018 ｜ 1477958418 ｜ 2026-11-06 00:00:00', ...
    'Position', [22 551 700 20], 'FontSize', 10.5, 'FontColor', [0.45 0.45 0.45]);

hb.in = uitextarea(hb.fig, 'Position', [22 340 818 205], 'Tag', 'batchInput', ...
    'FontSize', 12, 'Value', {'2443, 432018'; '2443, 120000'; ...
                              '1477958418'; '2026-11-06 00:00:00'});

uilabel(hb.fig, 'Text', '转换结果预览', 'Position', [22 312 200 20], ...
    'FontSize', 12, 'FontWeight', 'bold');
hb.out = uitextarea(hb.fig, 'Position', [22 100 818 205], 'Editable', 'off', ...
    'Tag', 'batchOutput', 'FontSize', 12, 'Value', {'（尚未转换）'});

hb.conv = uibutton(hb.fig, 'Text', '开始转换', 'Position', [22 40 120 36], ...
    'Tag', 'batchConvert', 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.15 0.42 0.72], 'FontColor', [1 1 1], ...
    'ButtonPushedFcn', @(src, evt) runBatch());
uibutton(hb.fig, 'Text', '导出结果…', 'Position', [154 40 120 36], ...
    'Tag', 'batchExport', 'ButtonPushedFcn', @(src, evt) exportBatch());
uibutton(hb.fig, 'Text', '清空', 'Position', [286 40 80 36], ...
    'Tag', 'batchClear', 'ButtonPushedFcn', @(src, evt) clearBatch());
uibutton(hb.fig, 'Text', '关闭', 'Position', [740 40 100 36], ...
    'Tag', 'batchClose', 'ButtonPushedFcn', @(src, evt) delete(hb.fig));

hb.status = uilabel(hb.fig, 'Text', '就绪：粘贴数据或用“载入文件…”', ...
    'Position', [22 12 760 20], 'Tag', 'batchStatus', ...
    'FontSize', 11, 'FontColor', [0.35 0.35 0.35]);

fig = hb.fig;

% ------------------------------------------------------------------
    function loadFile()
        [f, p] = uigetfile( ...
            {'*.txt;*.csv', '文本文件 (*.txt, *.csv)'; '*.*', '所有文件 (*.*)'}, ...
            '选择批量输入文件');
        if isequal(f, 0)
            return
        end
        try
            lines = readInputLines(fullfile(p, f));
            if isempty(lines)
                uialert(hb.fig, '文件中没有有效数据行。', '提示');
                return
            end
            hb.in.Value = lines;
            hb.status.Text = sprintf('已载入 %d 行：%s', numel(lines), f);
            hb.status.FontColor = [0.35 0.35 0.35];
        catch err
            uialert(hb.fig, err.message, '读取失败');
        end
    end

    function runBatch()
        try
            v = hb.in.Value;
            if ischar(v)
                v = {v};
            elseif isstring(v)
                v = cellstr(v);
            end
            switch hb.mode.Value
                case 'GPS 周 + 周内秒'
                    m = 'week';
                case 'GPS 累计秒'
                    m = 'sec';
                case 'UTC 时间'
                    m = 'utc';
                otherwise
                    m = 'auto';
            end
            T = batchConvert(v, m);
            hb.T = T;
            n = height(T);
            if n == 0
                hb.out.Value = {'没有可转换的数据行。'};
                hb.status.Text = '没有数据';
                hb.status.FontColor = [0.75 0.45 0.10];
                return
            end
            bad = sum(isnan(T.GPSWeek));
            hb.out.Value = previewBatch(T);
            hb.status.Text = sprintf('完成：共 %d 条，成功 %d 条，失败 %d 条', n, n - bad, bad);
            if bad > 0
                hb.status.FontColor = [0.75 0.45 0.10];
            else
                hb.status.FontColor = [0.12 0.45 0.20];
            end
        catch err
            hb.status.Text = '批量转换失败';
            hb.status.FontColor = [0.75 0.15 0.15];
            uialert(hb.fig, err.message, '批量转换失败');
        end
    end

    function exportBatch()
        if isempty(hb.T) || height(hb.T) == 0
            uialert(hb.fig, '请先执行批量转换，再导出结果。', '提示');
            return
        end
        [f, p] = uiputfile( ...
            {'*.xlsx', 'Excel 工作簿 (*.xlsx)'; '*.csv', 'CSV 文件 (*.csv, UTF-8)'}, ...
            '导出批量结果', 'GPS批量转换结果.xlsx');
        if isequal(f, 0)
            return
        end
        path = fullfile(p, f);
        try
            exportBatchTable(hb.T, path);
            hb.status.Text = sprintf('已导出 %d 条：%s', height(hb.T), path);
            hb.status.FontColor = [0.12 0.45 0.20];
        catch err
            uialert(hb.fig, err.message, '导出失败');
        end
    end

    function clearBatch()
        hb.in.Value = {''};
        hb.out.Value = {'（尚未转换）'};
        hb.T = [];
        hb.status.Text = '已清空';
        hb.status.FontColor = [0.35 0.35 0.35];
    end
end
