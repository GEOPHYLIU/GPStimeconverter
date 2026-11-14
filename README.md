# GPS 时间转换器

使 用 说 明 书

GPS Time Converter · User Manual

版本 V1.0



<table><tr><td rowspan=1 colspan=1>软件名称</td><td rowspan=1 colspan=1>GPS 时间转换器</td></tr><tr><td rowspan=1 colspan=1>英文名称</td><td rowspan=1 colspan=1>GPS Time Converter</td></tr><tr><td rowspan=1 colspan=1>程序文件</td><td rowspan=1 colspan=1>gpsTimeConverter.m</td></tr><tr><td rowspan=1 colspan=1>可执行文件</td><td rowspan=1 colspan=1>GPSTimeConverter.exe</td></tr><tr><td rowspan=1 colspan=1>版本号</td><td rowspan=1 colspan=1>V1.0</td></tr><tr><td rowspan=1 colspan=1>开发环境</td><td rowspan=1 colspan=1>MATLAB R2021a (9.10)</td></tr><tr><td rowspan=1 colspan=1>运行依赖</td><td rowspan=1 colspan=1>MATLAB R2021a 或 MATLAB Runtime 9.10；无需任何工具箱</td></tr><tr><td rowspan=1 colspan=1>编制日期</td><td rowspan=1 colspan=1>2026年11月6日</td></tr></table>



本说明书与软件 V1.0 配套使用

GPS 时间转换器 使用说明书

V1.0

## 目 录

1 概述  
2 运行环境  
3 安装与启动  
主界面说明  
单条转换  
6 批量转换  
命令行接口  
打包与分发  
9 常见问题  
10 维护与升级  
附录 A 自检方法  
附录 B 校验基准  
附录 C 版本记录

## 1 概述

## 1.1 编写目的

本说明书面向使用“GPS 时间转换器”进行 GPS 时间与协调世界时（UTC）换算的业务人员和技术人员，说明软件的功能特点、界面操作、批量处理、脚本接口、打包分发方法以及常见问题的处理。阅读对象无需了解 GPS 时与 UTC 的换算细节，按本说明操作即可得到正确结果。

## 1.2 软件简介

GPS 时间转换器是一款基于 MATLAB 开发的轻量级时间换算工具，用于 GPS 时与 UTC 的双向换算，支持单条与批量两种作业方式。软件为单文件实现（gpsTimeConverter.m），不依赖任何工具箱，既可在 MATLAB 中直接运行，也可打包为独立 Windows 程序（GPSTimeConverter.exe）。

软件界面简洁，换算结果同时给出 UTC 时间、北京时间、GPS 周/周内秒、GPS 累计秒、闰秒差、周内第几天与儒略日，便于直接摘录进周报、日报或技术记录。

第 2 页

GPS 时间转换器 使用说明书

V1.0

## 1.3 主要功能

• 三种单条换算方向：GPS 周 + 周内秒 → UTC；GPS 累计秒 → UTC；UTC → GPS 周 / 周内秒。

• 闰秒处理：内置 1981—2017 年共 18 次闰秒，可正确表示并换算 UTC 23:59:60。

• 批量换算：粘贴或导入 txt / csv 文件，逐行自动识别，单行失败不影响其余记录。

• 结果导出：CSV（UTF-8 带 BOM，Excel 直接打开不乱码）与 Excel 工作簿（.xlsx）。

• 辅助信息：北京时间、周内第几天、儒略日、GPS−UTC 闰秒差，一键复制结果。

• 脚本接口：可在 MATLAB 脚本或批处理中直接调用，返回结构体或表格。

• 可打包：通过 MATLAB Compiler 生成独立 exe，目标机只需安装对应版本 MATLAB Runtime。

## 1.4 换算约定

为避免歧义，本软件的换算遵循以下约定：

• GPS 时起点为 1980-01-06 00:00:00 UTC（即 GPS 周 0、周内秒 0）。

• GPS 时为连续原子时，不含闰秒；UTC 含闰秒。

• 换算关系：UTC = GPS −（GPS−UTC 累计闰秒差）。自 2017-01-01 起该差值为 18 s。

• 周内秒取值范围为 [0, 604800)，604800 属于下一周的第 0 秒。

• 时间输出精确到毫秒；北京时间 = UTC + 8 h。

• 闰秒时刻按 UTC 23:59:60 显示，此时 GPS−UTC 仍为闰秒前的值，下一秒才递增。

## 1.5 术语



<table><tr><td rowspan=1 colspan=1>术语</td><td rowspan=1 colspan=1>含义</td></tr><tr><td rowspan=1 colspan=1>GPS 周</td><td rowspan=1 colspan=1>自 1980-01-06 起累计的整周数，每周从周日 00:00 开始</td></tr><tr><td rowspan=1 colspan=1>周内秒</td><td rowspan=1 colspan=1>当前周内已过去的秒数，0≤秒<604800</td></tr><tr><td rowspan=1 colspan=1>GPS 累计秒</td><td rowspan=1 colspan=1>自 GPS 起点起算的总秒数 = GPS 周 × 604800 + 周内秒</td></tr><tr><td rowspan=1 colspan=1>GPS-UTC 闰秒差</td><td rowspan=1 colspan=1>GPS 时与 UTC 的累计差值，当前为 18 s</td></tr><tr><td rowspan=1 colspan=1>闰秒</td><td rowspan=1 colspan=1>UTC 为保持与地球自转同步而插入的 1 s，表现为 23:59:60</td></tr><tr><td rowspan=1 colspan=1>儒略日</td><td rowspan=1 colspan=1>以公元前 4713 年 1 月 1 日 12 时为起点的连续日计数</td></tr></table>



第 3 页

GPS 时间转换器 使用说明书

V1.0

## 2 运行环境

## 2.1 操作系统

Windows 10 / Windows 11（64 位）。以源码方式运行时，也可在 MATLAB 支持的其他操作系统上使用。

## 2.2 源码运行环境

• MATLAB R2021a（已测试通过）。建议使用 R2018b 及以上版本。

• 不需要任何工具箱，仅使用 MATLAB 基础功能（datetime、table、uifigure 等）。

• 低版本 MATLAB 若个别界面属性不支持，程序会自动降级（例如批量窗口的模态属性），不影响换算功能。

## 2.3 独立程序运行环境

• 需安装与打包所用 MATLAB 版本一致的 MATLAB Runtime。本程序使用 R2021a 打包，对应Runtime 9.10。

• MATLAB Runtime 可从 MathWorks 官网免费下载，安装需要管理员权限。

• 目标机无需安装 MATLAB，也无需任何工具箱。

## 2.4 显示要求

建议分辨率 1280×800 及以上。主界面尺寸 780×590，批量窗口 860×660，启动时自动居中显示。

## 3 安装与启动

## 3.1 源码方式

1）将 gpsTimeConverter.m 复制到工作目录（路径可含中文，建议避免特殊符号）。

2）启动 MATLAB，将“当前文件夹”切换到该目录。

3）在命令行窗口输入 gpsTimeConverter 并回车；或在编辑器中打开文件后按 F5 运行。

注意：文件名必须为 gpsTimeConverter.m，且不要与其他同名函数冲突，否则 MATLAB 可能调用到错误的文件。

第 4 页

GPS 时间转换器 使用说明书

V1.0

## 3.2 独立程序方式

1）确认目标机已安装 MATLAB Runtime 9.10。

2）双击 GPSTimeConverter.exe。

3）首次启动需数秒至十余秒（Runtime 初始化），请耐心等待。

若提示找不到 MATLAB Runtime，请先安装 Runtime；或在与打包版本一致的 MATLAB 中重新打包。

## 3.3 启动后的默认状态

启动后软件自动完成三件事：按当前 UTC 时间填充各输入框；默认方向为“GPS 周 + 周内秒→ UTC”；结果区显示一次示例换算结果。用户可直接修改输入框内容后重新转换。

## 4 主界面说明

![](images/bc03cd8be15053a39c8e82a552f1adb5e2c69319f0145c95ca109935dfba13a7.jpg)



图 1 主界面


第 5 页

GPS 时间转换器 使用说明书

V1.0

## 4.1 界面布局

界面自上而下分为四个区域：标题与换算约定提示区；输入区（转换方向、GPS 周、周内秒、GPS 累计秒、UTC 时间）；操作按钮区（开始转换、复制结果、闰秒表、清空、批量转换）；结果区。

## 4.2 控件说明



<table><tr><td rowspan=1 colspan=1>控件</td><td rowspan=1 colspan=1>说明</td></tr><tr><td rowspan=1 colspan=1>转换方向</td><td rowspan=1 colspan=1>选择换算方向，共三种：GPS 周 + 周内秒 → UTC；GPS 累计秒 → UTC；UTC → GPS周/周内秒</td></tr><tr><td rowspan=1 colspan=1>GPS 周</td><td rowspan=1 colspan=1>自1980-01-06 起的整周数，非负整数</td></tr><tr><td rowspan=1 colspan=1>周内秒</td><td rowspan=1 colspan=1>当前周内秒数，0~604799.999</td></tr><tr><td rowspan=1 colspan=1>GPS 累计秒</td><td rowspan=1 colspan=1>自 GPS 起点起算的总秒数，可带小数</td></tr><tr><td rowspan=1 colspan=1>UTC 时间</td><td rowspan=1 colspan=1>待换算的 UTC 日期时间，支持多种书写格式（见 5.4 节）</td></tr><tr><td rowspan=1 colspan=1>现在 (UTC)</td><td rowspan=1 colspan=1>一键填入当前 UTC 时间，并切换到“UTC →GPS”方向执行换算</td></tr><tr><td rowspan=1 colspan=1>开始转换</td><td rowspan=1 colspan=1>按当前方向执行换算</td></tr><tr><td rowspan=1 colspan=1>复制结果</td><td rowspan=1 colspan=1>将结果区文本复制到系统剪贴板</td></tr><tr><td rowspan=1 colspan=1>闰秒表</td><td rowspan=1 colspan=1>在结果区列出1980年以来全部闰秒的生效日期与累计差值</td></tr><tr><td rowspan=1 colspan=1>清空</td><td rowspan=1 colspan=1>清空全部输入框与结果区</td></tr><tr><td rowspan=1 colspan=1>批量转换</td><td rowspan=1 colspan=1>打开批量转换窗口（见第 6章）</td></tr><tr><td rowspan=1 colspan=1>状态提示</td><td rowspan=1 colspan=1>显示转换状态、完成时间或错误提示，正常为绿色、异常为红色</td></tr></table>



## 4.3 结果字段说明



<table><tr><td rowspan=1 colspan=1>字段</td><td rowspan=1 colspan=1>说明</td><td rowspan=1 colspan=1>示例</td></tr><tr><td rowspan=1 colspan=1>UTC 时间</td><td rowspan=1 colspan=1>换算得到的 UTC 日期时间，毫秒精度</td><td rowspan=1 colspan=1>2026-11-0600:00:00.000</td></tr><tr><td rowspan=1 colspan=1>北京时间(UTC+8)</td><td rowspan=1 colspan=1>UTC 加 8 小时</td><td rowspan=1 colspan=1>2026-11-0608:00:00.000</td></tr><tr><td rowspan=1 colspan=1>GPS 周 / 周内秒</td><td rowspan=1 colspan=1>GPS 周数与周内秒数</td><td rowspan=1 colspan=1>2443 / 432018.000 s</td></tr><tr><td rowspan=1 colspan=1>GPS 累计秒</td><td rowspan=1 colspan=1>自 GPS 起点起算的总秒数</td><td rowspan=1 colspan=1>1477958418.000s</td></tr><tr><td rowspan=1 colspan=1>GPS-UTC 闰秒差</td><td rowspan=1 colspan=1>当前生效的累计闰秒差</td><td rowspan=1 colspan=1>18 s</td></tr><tr><td rowspan=1 colspan=1>周内第几天</td><td rowspan=1 colspan=1>周内序号（周日为第1天）及星期</td><td rowspan=1 colspan=1>第 6天（周五）</td></tr><tr><td rowspan=1 colspan=1>儒略日(UTC)</td><td rowspan=1 colspan=1>对应 UTC 时刻的儒略日</td><td rowspan=1 colspan=1>2461350.500000</td></tr></table>



## 4.4 操作约定

• 方向联动：切换“转换方向”后，与当前方向无关的输入框自动置灰，避免误填。

• 回车快捷：在任一输入框中按回车，软件会自动切换到该输入框对应的换算方向并立即转换。

• 出错提示：输入非法时弹出提示框，状态栏变为红色；修正后再次转换即可。

第 6 页

GPS 时间转换器 使用说明书

V1.0

• 结果复制：点击“复制结果”后可直接粘贴到邮件、周报或技术记录中。

## 5 单条转换

## 5.1 GPS 周 + 周内秒 → UTC

操作步骤：

1）在“转换方向”中选择“GPS 周 + 周内秒 -> UTC”。

2）在“GPS 周”中输入 2443，在“周内秒”中输入 432018。

3）点击“开始转换”。

结果：UTC 时间 2026-11-06 00:00:00.000；北京时间 2026-11-06 08:00:00.000；GPS 累计秒 1477958418.000；GPS−UTC 闰秒差 18 s。

## 5.2 GPS 累计秒 → UTC

在“转换方向”中选择“GPS 累计秒 -> UTC”，在“GPS 累计秒”中输入 1477958418，点击“开始转换”，结果与 5.1 节示例一致。该方式适合接收机直接输出总秒数的场景。

## 5.3 UTC → GPS

在“转换方向”中选择“UTC -> GPS 周 / 周内秒”，在“UTC 时间”中输入 2026-11-0600:00:00，点击“开始转换”，结果为 GPS 周 2443、周内秒 432018、累计秒 1477958418。

## 5.4 支持的 UTC 输入格式



<table><tr><td rowspan=1 colspan=1>输入示例</td><td rowspan=1 colspan=1>说明</td></tr><tr><td rowspan=1 colspan=1>2026-11-0600:00:00</td><td rowspan=1 colspan=1>标准格式</td></tr><tr><td rowspan=1 colspan=1>2026-11-0600:00:00.123</td><td rowspan=1 colspan=1>带毫秒</td></tr><tr><td rowspan=1 colspan=1>2026/11/0608:30:00</td><td rowspan=1 colspan=1>斜杠分隔</td></tr><tr><td rowspan=1 colspan=1>2026年11月6日8:30</td><td rowspan=1 colspan=1>中文日期</td></tr><tr><td rowspan=1 colspan=1>2026-11-06T00:00:00</td><td rowspan=1 colspan=1>ISO 8601，T 分隔</td></tr><tr><td rowspan=1 colspan=1>2026-11-06T00:00:00Z</td><td rowspan=1 colspan=1>带时区，先换算为 UTC 再参与计算</td></tr></table>




说明：月、日、时、分允许一位或两位数字；秒可带 1\~3 位小数，输出统一保留 3 位小数。


## 5.5 闰秒输入

UTC 输入支持 23:59:60 写法。例如输入 2016-12-31 23:59:60，换算得到 GPS 累计秒1167264017，结果区显示 2016-12-31 23:59:60.000，并注明该时刻为闰秒。

第 7 页

GPS 时间转换器 使用说明书

V1.0

若输入的 23:59:60 所在日期并非闰秒日（即次日不是闰秒生效日），软件会提示“输入的23:59:60 所在日期不存在闰秒”，可按“闰秒表”按钮核对闰秒日期。

## 6 批量转换

![](images/f95e9fdf915421bbede365cdd033a30ec9b4c2ec579d2e80c1c9a08d90dc8802.jpg)



图 2 批量转换窗口


## 6.1 打开方式

在主界面点击“批量转换”，或在 MATLAB 命令行执行 gpsTimeConverter('batchdialog')。

## 6.2 输入规则

每行一条记录，支持以下三种写法，可混用（自动识别模式）：



<table><tr><td rowspan=1 colspan=1>输入示例</td><td rowspan=1 colspan=1>含义</td></tr><tr><td rowspan=1 colspan=1>2443,432018</td><td rowspan=1 colspan=1>GPS周+周内秒（逗号、空格、制表符均可）</td></tr><tr><td rowspan=1 colspan=1>1477958418</td><td rowspan=1 colspan=1>GPS 累计秒</td></tr><tr><td rowspan=1 colspan=1>2026-11-0600:00:00</td><td rowspan=1 colspan=1>UTC 时间</td></tr></table>




• 空行自动忽略；以 # 开头的行视为注释。


第 8 页

GPS 时间转换器 使用说明书

V1.0

• 首行若不含任何数字，视为表头并跳过。

• 可直接从 Excel 复制多行后粘贴（制表符分隔）。

• 若粘贴的是 Excel 日期序列号（如 45678.5），请先在 Excel 中格式化为日期时间文本。

## 6.3 输入格式选项



<table><tr><td rowspan=1 colspan=1>选项</td><td rowspan=1 colspan=1>解析规则</td></tr><tr><td rowspan=1 colspan=1>自动识别（推荐）</td><td rowspan=1 colspan=1>逐行判断：含“四位数字 +年/月/日分隔符”按UTC解析；含两个数值按周+周内秒；含一个数值按累计秒；其余按UTC解析，失败写入备注</td></tr><tr><td rowspan=1 colspan=1>GPS 周 + 周内秒</td><td rowspan=1 colspan=1>所有行均按“周，周内秒”解析</td></tr><tr><td rowspan=1 colspan=1>GPS 累计秒</td><td rowspan=1 colspan=1>所有行均按一个数值（累计秒）解析</td></tr><tr><td rowspan=1 colspan=1>UTC 时间</td><td rowspan=1 colspan=1>所有行均按日期时间解析</td></tr></table>




数据列固定时建议显式选择格式，避免个别行被误判。


## 6.4 载入文件

点击“载入文件…”，选择 .txt 或 .csv 文件（UTF-8 或系统默认编码均可）。软件读取全部非空行填入输入框，并在状态栏显示载入行数与文件名。

## 6.5 开始转换与预览

点击“开始转换”后，结果区首行显示“共 N 条，成功 X 条，失败 Y 条”，随后按序号预览前 200 条记录，包括 UTC 时间、GPS 周/周内秒与 GPS 累计秒。

单行失败不会中断转换：该行在备注中给出原因，其余记录照常换算。记录数超过 200 条时，预览末尾提示“仅预览前 200 条”，导出结果包含全部数据。

## 6.6 导出结果

点击“导出结果…”，在保存对话框中选择 .xlsx 或 .csv：

• Excel 工作簿（.xlsx）：可直接用 Excel 打开，表头为中文。

• CSV 文件（.csv）：采用 UTF-8 编码并写入 BOM，Excel 双击打开中文不乱码；若用其他工具处理，请按 UTF-8 读取。

导出字段共 9 列：



<table><tr><td colspan="1" rowspan="1">列名</td><td colspan="1" rowspan="1">说明</td></tr><tr><td colspan="1" rowspan="1">序号</td><td colspan="1" rowspan="1">记录在本次批量中的顺序号</td></tr><tr><td colspan="1" rowspan="1">输入</td><td colspan="1" rowspan="1">该行的原始输入文本</td></tr><tr><td colspan="1" rowspan="1">UTC 时间</td><td colspan="1" rowspan="1">换算得到的 UTC 时间（毫秒精度）</td></tr><tr><td colspan="1" rowspan="1">北京时间</td><td colspan="1" rowspan="1">UTC + 8 小时</td></tr><tr><td colspan="1" rowspan="1">GPS 周</td><td colspan="1" rowspan="1">GPS 周数；失败行为空</td></tr><tr><td colspan="1" rowspan="1">周内秒</td><td colspan="1" rowspan="1">周内秒数；失败行为空</td></tr><tr><td colspan="1" rowspan="1">GPS 累计秒</td><td colspan="1" rowspan="1">自 GPS 起点起算的总秒数；失败行为空</td></tr><tr><td colspan="1" rowspan="1">GPS-UTC 闰秒</td><td colspan="1" rowspan="1">当前累计闰秒差；失败行为空</td></tr><tr><td colspan="1" rowspan="1">备注</td><td colspan="1" rowspan="1">闰秒提示或失败原因</td></tr></table>



第 9 页

GPS 时间转换器 使用说明书

V1.0

## 6.7 使用建议

• 接收机导出的周/周内秒文件，建议选用“GPS 周 + 周内秒”模式，失败行按备注单独核对。

• 数万行的大批量数据，建议直接导出 xlsx 后统计，避免在预览区反复滚动。

• 批量结果可直接作为周报、日报的附表存档，导出文件自带中文表头与时间字段。

## 7 命令行接口

除图形界面外，软件提供命令行 / 脚本接口，便于自动化处理与批量作业。



<table><tr><td rowspan=1 colspan=1>命令</td><td rowspan=1 colspan=1>用途</td></tr><tr><td rowspan=1 colspan=1>gpsTimeConverter</td><td rowspan=1 colspan=1>打开图形界面</td></tr><tr><td rowspan=1 colspan=1>gpsTimeConverter(&#x27;gps2utc&#x27;, week, tow)</td><td rowspan=1 colspan=1>GPS 周 + 周内秒 → 结果结构体</td></tr><tr><td rowspan=1 colspan=1>gpsTimeConverter(&#x27;gps2utc&#x27;, sec)</td><td rowspan=1 colspan=1>GPS 累计秒 → 结果结构体</td></tr><tr><td rowspan=1 colspan=1>gpsTimeConverter(&#x27;utc2gps&#x27;, &#x27;2026-11-06 00:00:00&#x27;)</td><td rowspan=1 colspan=1>UTC → 结果结构体</td></tr><tr><td rowspan=1 colspan=1>gpsTimeConverter(&#x27;batch&#x27;, records [, mode])</td><td rowspan=1 colspan=1>批量换算 → 表格</td></tr><tr><td rowspan=1 colspan=1>gpsTimeConverter(&#x27;batch&#x27;, &#x27;input.txt&#x27;)</td><td rowspan=1 colspan=1>从文本文件批量换算 → 表格</td></tr><tr><td rowspan=1 colspan=1>gpsTimeConverter(&#x27;export&#x27;, T, &#x27;result.csv&#x27;)</td><td rowspan=1 colspan=1>导出批量结果（csv /xlsx）</td></tr><tr><td rowspan=1 colspan=1>gpsTimeConverter(&#x27;batchdialog&#x27;)</td><td rowspan=1 colspan=1>打开批量转换窗口</td></tr><tr><td rowspan=1 colspan=1>gpsTimeConverter(&#x27;leaptable&#x27;)</td><td rowspan=1 colspan=1>返回闰秒表</td></tr></table>



## 7.1 单条返回结构体



<table><tr><td rowspan=1 colspan=1>字段</td><td rowspan=1 colspan=1>说明</td></tr><tr><td rowspan=1 colspan=1>gpsSeconds</td><td rowspan=1 colspan=1>GPS 累计秒</td></tr><tr><td rowspan=1 colspan=1>gpsWeek / gpsTow</td><td rowspan=1 colspan=1>GPS 周 / 周内秒</td></tr><tr><td rowspan=1 colspan=1>leapSeconds</td><td rowspan=1 colspan=1>GPS-UTC闰秒差（s）</td></tr><tr><td rowspan=1 colspan=1>isLeapSecond</td><td rowspan=1 colspan=1>是否为闰秒时刻（true / false）</td></tr><tr><td rowspan=1 colspan=1>utcText / beijingText</td><td rowspan=1 colspan=1>格式化后的 UTC 时间 / 北京时间文本</td></tr><tr><td rowspan=1 colspan=1>utc</td><td rowspan=1 colspan=1>datetime 对象（UTC）</td></tr><tr><td rowspan=1 colspan=1>julianDate</td><td rowspan=1 colspan=1>儒略日</td></tr><tr><td rowspan=1 colspan=1>dowIndex / dowName</td><td rowspan=1 colspan=1>周内序号（0 = 周日）/中文星期</td></tr></table>



第 10 页

GPS 时间转换器 使用说明书

V1.0

## 7.2 批量返回表

批量命令返回 MATLAB table，列名为：Index、Input、UTC、Beijing、GPSWeek、GPSTow、GPSSec、GPS\_UTC、Note。失败行的数值列为 NaN，Note 中给出失败原因。

## 7.3 脚本示例

```matlab
% 1) 单条换算
r = gpsTimeConverter('gps2utc', 2443, 432018);
fprintf('%s (GPS-UTC = %d s)\n', r.utcText, r.leapSeconds);
% 2) 批量：直接给数值矩阵（周、周内秒）
T = gpsTimeConverter('batch', [2443 432018; 2444 0]);
% 3) 批量：读文件，并单独导出失败行
T = gpsTimeConverter('batch', 'input.txt');
bad = T(isnan(T.GPSWeek), :);
if height(bad) > 0
gpsTimeConverter('export', bad, '失败行.csv');
end
% 4) 导出全部结果
gpsTimeConverter('export', T, '结果.xlsx');
```

## 8 打包与分发

## 8.1 图形化打包（推荐）

1）在 MATLAB 命令行输入 deploytool，打开“Application Compiler”。

2）“主文件”选择 gpsTimeConverter.m，其余依赖由环境自动识别。

3）填写应用名称（如 GPSTimeConverter）、版本与作者信息。

4）选择 Runtime 获取方式：从网络下载，或将 Runtime 打包进安装包（体积较大，适合离线分发）。

5）点击“Package”，生成 exe 与 readme.txt。

## 8.2 命令行打包

mcc -m gpsTimeConverter.m -o GPSTimeConverter生成 GPSTimeConverter.exe、readme.txt、requiredMCRProducts.txt 等文件。若unresolvedSymbols.txt 为空，表示没有未解析符号，打包完整。

## 8.3 目标机部署

• 将 exe 与 readme.txt 复制到目标机（目录可含中文）。

第 11 页

GPS 时间转换器 使用说明书

V1.0

• 安装与打包版本一致的 MATLAB Runtime（本程序为 9.10 / R2021a）。

• 双击 exe 运行。目标机无需安装 MATLAB，也无需任何工具箱。

## 8.4 注意事项

• exe 与 Runtime 版本必须匹配；更换 MATLAB 版本后需重新打包。

• 若修改了 .m 文件名，函数名需同步修改，否则打包后无法正常启动。

• 路径含中文一般可用；若遇异常，可尝试放到纯英文路径下运行。

• 打包机需安装 MATLAB Compiler；目标机只需 MATLAB Runtime。

## 9 常见问题



<table><tr><td rowspan=1 colspan=1>问题现象</td><td rowspan=1 colspan=1>原因与处理方法</td></tr><tr><td rowspan=1 colspan=1>双击 exe 无反应，或提示找不到 Runtime</td><td rowspan=1 colspan=1>未安装 MATLAB Runtime 或版本不匹配。安装 9.10 版Runtime；或使用与打包一致的 MATLAB版本重新打包。</td></tr><tr><td rowspan=1 colspan=1>CSV 用 Excel 打开中文乱码</td><td rowspan=1 colspan=1>本软件导出的 CSV 已带 UTF-8 BOM，正常不会乱码；若曾用其他工具另存，请在保存时选择“CSV UTF-8”格式。</td></tr><tr><td rowspan=1 colspan=1>输入23:59:60提示“不存在闰秒”</td><td rowspan=1 colspan=1>只有闰秒生效日的前一日才存在23:59:60。可点击“闰秒表”查看全部闰秒日期。</td></tr><tr><td rowspan=1 colspan=1>周内秒填 604800 报错</td><td rowspan=1 colspan=1>周内秒范围为 0~604799.999；604800 应记为下一周的第 0秒。</td></tr><tr><td rowspan=1 colspan=1>GPS 周数很大（大于 1023）</td><td rowspan=1 colspan=1>程序按连续周数计算。部分接收机使用10位周计数（0~1023）会回卷，需在接收机周数上加上1024 的整数倍后再输入。</td></tr><tr><td rowspan=1 colspan=1>批量转换有少量行失败</td><td rowspan=1 colspan=1>查看导出结果“备注”列给出的原因，常见为格式不符、日期非法或周内秒越界；修正该行后重新转换即可。</td></tr><tr><td rowspan=1 colspan=1>提示“无法识别的时间格式”</td><td rowspan=1 colspan=1>按5.4节列出的格式输入；注意顺序为“年-月-日”，且不要夹带多余文字。</td></tr><tr><td rowspan=1 colspan=1>点击“复制结果”无反应</td><td rowspan=1 colspan=1>系统剪贴板可能被其他程序占用，稍后重试；也可手动选中结果文本复制。</td></tr><tr><td rowspan=1 colspan=1>界面中文显示为方块</td><td rowspan=1 colspan=1>系统缺少中文字体。安装常用中文字体（如微软雅黑、宋体）后重启软件。</td></tr><tr><td rowspan=1 colspan=1>能否在未安装 MATLAB 的电脑上使用</td><td rowspan=1 colspan=1>可以。使用打包后的 exe，并安装对应版本 MATLAB Runtime即可。</td></tr></table>



第 12 页

GPS 时间转换器 使用说明书

V1.0

## 10 维护与升级

## 10.1 新增闰秒

若国际地球自转服务组织（IERS）公布新的闰秒，只需修改 gpsTimeConverter.m 中leapTable 函数的 utcDate 矩阵，在末尾追加闰秒生效的 UTC 日期（年 月 日）即可；累计值由程序按顺序自动生成，单条换算、批量换算与闰秒表会同时生效。修改后请运行自检脚本确认，并重新打包 exe。

## 10.2 修改界面文字或默认值

界面文字、启动时的示例数据、批量预览条数（previewBatch 的 maxRows，默认 200）均可在源码中直接修改。

## 10.3 修改后的验证

每次修改后建议执行 test\_gps\_converter 自检（见附录 A），确认 93 项检查全部通过，再重新打包分发。

## 10.4 版本管理建议

保留每次发布的 .m 源文件与 exe，并在附录 C 版本记录中登记修改内容与日期，便于回溯。

第 13 页

GPS 时间转换器 使用说明书

V1.0

## 附录 A 自检方法

1）将 gpsTimeConverter.m 与 test\_gps\_converter.m 放在同一目录。

2）在 MATLAB 中运行 test\_gps\_converter，或在系统命令行执行：

matlab -batch "test\_gps\_converter"

3）自检覆盖核心换算、闰秒、往返一致性、多种时间格式、异常输入、批量与文件导出、界面交互等 93 项检查。

4）全部通过时输出“结果：PASS”，并生成 test\_report.txt；若存在失败项，将逐条列出失败名称，便于定位。

5）自检会在当前目录生成 batch\_out.csv、batch\_out.xlsx 等样例文件，可自行删除。

## 附录 B 校验基准

下列基准可用于验收或二次开发时的回归测试：



<table><tr><td rowspan=1 colspan=1>输入</td><td rowspan=1 colspan=1>输出</td></tr><tr><td rowspan=1 colspan=1>GPS 周 0 / 周内秒 0</td><td rowspan=1 colspan=1>1980-01-06 00:00:00.000 (GPS-UTC = 0 s)</td></tr><tr><td rowspan=1 colspan=1>GPS 周 1930 / 周内秒 18</td><td rowspan=1 colspan=1>2017-01-01 00:00:00.000 (GPS-UTC = 18 s)</td></tr><tr><td rowspan=1 colspan=1>GPS 累计秒 1167264017</td><td rowspan=1 colspan=1>2016-12-3123:59:60.000（闰秒）</td></tr><tr><td rowspan=1 colspan=1>GPS 周 2443 / 周内秒 432018</td><td rowspan=1 colspan=1>2026-11-0600:00:00.000</td></tr><tr><td rowspan=1 colspan=1>UTC 2026-11-06 00:00:00</td><td rowspan=1 colspan=1>GPS 周 2443 / 周内秒 432018 / 累计秒 1477958418</td></tr></table>



## 附录 C 版本记录



<table><tr><td rowspan=1 colspan=1>版本</td><td rowspan=1 colspan=1>日期</td><td rowspan=1 colspan=1>修改说明</td></tr><tr><td rowspan=1 colspan=1>V1.0</td><td rowspan=1 colspan=1>2026-11-06</td><td rowspan=1 colspan=1>首次发布：单条双向换算、闰秒处理、批量转换与导出、命令行接口、可打包为独立程序</td></tr></table>



第 14 页
