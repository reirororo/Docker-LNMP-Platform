<?php
error_reporting(E_ALL);
$app_env = getenv("APP_ENV") ?: "dev";
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>LNMP Platform - System Probe</title>
<style>
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f0f2f5; margin: 0; padding: 20px; color: #333; }
.container { max-width: 900px; margin: 0 auto; }
h1 { text-align: center; color: #1a73e8; }
.badge { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 14px; font-weight: bold; }
.badge.dev { background: #e8f5e9; color: #2e7d32; }
.badge.prod { background: #ffebee; color: #c62828; }
.card { background: #fff; border-radius: 8px; padding: 20px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
.card h2 { margin-top: 0; font-size: 18px; border-bottom: 1px solid #eee; padding-bottom: 8px; }
.dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 6px; }
.dot.ok { background: #4caf50; }
.dot.fail { background: #f44336; }
table { width: 100%; border-collapse: collapse; }
td, th { padding: 8px 12px; text-align: left; border-bottom: 1px solid #f0f0f0; }
th { background: #fafafa; font-weight: 600; }
.ok { color: #4caf50; font-weight: bold; }
.fail { color: #f44336; font-weight: bold; }
</style>
</head>
<body>
<div class="container">
<h1>LNMP 平台 <span class="badge <?= $app_env ?>"><?= htmlspecialchars($app_env) ?></span></h1>
<div class="card">
<h2>服务状态</h2>
<table>
<?php
$checks = [];
try {
    $pdo = new PDO("mysql:host=".(getenv("MYSQL_HOST")?:"mysql").";dbname=".(getenv("MYSQL_DATABASE")?:"app").";charset=utf8mb4", getenv("MYSQL_USER")?:"appuser", getenv("MYSQL_PASSWORD")?:"apppass", [PDO::ATTR_TIMEOUT=>3, PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
    $row = $pdo->query("SELECT COUNT(*) as cnt FROM users")->fetch(PDO::FETCH_ASSOC);
    $checks["MySQL"] = [true, "已连接，用户表共 {$row["cnt"]} 条记录"];
} catch (Exception $e) { $checks["MySQL"] = [false, $e->getMessage()]; }
try {
    $r = new Redis(); $r->connect(getenv("REDIS_HOST")?:"redis", 6379, 3); $r->auth(getenv("REDIS_PASSWORD")?:"redispass"); $r->ping();
    $checks["Redis"] = [true, "已连接"]; $r->close();
} catch (Exception $e) { $checks["Redis"] = [false, $e->getMessage()]; }
$checks["PHP"] = [true, phpversion()];
foreach ($checks as $name => $r): ?>
<tr><td><span class="dot <?= $r[0]?"ok":"fail" ?>"></span><?= htmlspecialchars($name) ?></td><td><?= htmlspecialchars($r[1]) ?></td></tr>
<?php endforeach; ?>
</table></div>
<div class="card">
<h2>PHP 扩展</h2>
<table>
<?php foreach (["pdo_mysql","mysqli","redis","json","mbstring","curl","gd"] as $ext): ?>
<tr><td><?= $ext ?></td><td class="<?= extension_loaded($ext)?"ok":"fail" ?>"><?= extension_loaded($ext)?"✅ 已加载":"❌ 缺失" ?></td></tr>
<?php endforeach; ?>
</table></div>
<div class="card">
<h2>服务器信息</h2>
<table>
<tr><td>Server</td><td><?= htmlspecialchars($_SERVER["SERVER_SOFTWARE"]??"N/A") ?></td></tr>
<tr><td>PHP 版本</td><td><?= phpversion() ?></td></tr>
<tr><td>服务器 IP</td><td><?= htmlspecialchars($_SERVER["SERVER_ADDR"]??"N/A") ?></td></tr>
<tr><td>请求时间</td><td><?= date("Y-m-d H:i:s") ?></td></tr>
</table></div>
</div>
</body>
</html>
