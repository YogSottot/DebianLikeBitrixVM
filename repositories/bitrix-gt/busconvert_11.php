<?
header("Content-Type: text/html; charset=utf-8");

##################################
const BUSCONVERT_VERSION = '1.1.0';
##################################

const STOP_STATISTICS          = true;
const NO_KEEP_STATISTIC        = true;
const NO_AGENT_STATISTIC       = true;
const DisableEventsCheck       = true;
const BX_SECURITY_SHOW_MESSAGE = false;

const LANGUAGE_ID = 'ru';
//define('SITE_ID', 's1');

if(ini_get('short_open_tag') == 0)
  die("Error: short_open_tag parameter must be turned on in php.ini\n");

// CLI DOCUMENT_ROOT
if(empty($_SERVER['DOCUMENT_ROOT']))
  $_SERVER['DOCUMENT_ROOT'] = realpath(dirname(__FILE__) .'/..');

if(empty($_SERVER['DOCUMENT_ROOT']))
  die("Error! \"DOCUMENT_ROOT\" parameter must be not empty\n");

use Bitrix\Main\Application;

//https://dev.mysql.com/doc/refman/5.7/en/charset-conversion.html
require($_SERVER['DOCUMENT_ROOT'] . '/bitrix/modules/main/include/prolog_before.php');

global $USER, $APPLICATION;

// Rewrite Bitrix settings
error_reporting(E_ERROR | E_WARNING | E_PARSE);
ini_set('display_errors', 1);
//ini_set('memory_limit', '512M');

@set_time_limit(0);
@ignore_user_abort(true);

// if(!$USER->IsAdmin())
//   $APPLICATION->AuthForm(Loc::getMessage('ACCESS_DENIED'));

// DB settings
// $connections = \Bitrix\Main\Config\Configuration::getValue('connections');
// $connection  = $connections['default'];
//
// $DBHost     = trim($connection['host']);
// $DBLogin    = trim($connection['login']);
// $DBPassword = trim($connection['password']);
// $DBName     = trim($connection['database']);

// Bitrix settings
$context = Application::getInstance()->getContext();
$request = $context->getRequest();
$server  = $context->getServer();

$connect = Application::getConnection();
$helper  = $connect->getSqlHelper();
$config  = $connect->getConfiguration();

// DB settings
$DBHost     = trim($config['host']);
$DBLogin    = trim($config['login']);
$DBPassword = trim($config['password']);
$DBName     = trim($config['database']);

if(empty($DBName)){
  throw new Exception('Error! Empty $DBName settings');
}

//SHOW STATUS;
//SHOW VARIABLES;
//USE `table`;
//SHOW COLLATION;
//SHOW VARIABLES LIKE 'collation_server';
//SHOW TABLE STATUS FROM `table`;
//SHOW TRIGGERS FROM `table`;
//SHOW EVENTS FROM `table`;

#**********************************************************
#                     VARS
#**********************************************************

//$charset   = 'utf8';
//$collate   = 'utf8_unicode_ci';

$charset = 'utf8mb4';
$collate = 'utf8mb4_unicode_ci';

$arConvert = [
  //'national char',
  //'nchar',
  //'national varchar',
  //'nvarchar',
  'char',
  'varchar',
  'tinytext',
  'text',
  'mediumtext',
  'longtext',
  'enum',
  'set',
  'json',
];

$Convert   = !empty($request['Convert']);
$bSendMail = !empty($request['send_mail']);

$messOk    = [];
$messError = [];

#**********************************************************
#                     ДО КОНВЕРТАЦИИ
#**********************************************************

$collationList = [];
$charsetList   = [];

$res = $connect->query("SHOW VARIABLES WHERE Variable_name LIKE 'collation%';");
while($row = $res->fetch()){
  $collationList[$row['Variable_name']] = $row['Value'];
}

$res = $connect->query("SHOW VARIABLES WHERE Variable_name LIKE 'character%';");
while($row = $res->fetch()){
  //if($row['Variable_name'] == 'character_set_filesystem' || $row['Variable_name'] == 'character_set_system')
  //continue;

  if($row['Value'] == 'binary')
    continue;

  $charsetList[$row['Variable_name']] = $row['Value'];
}

// varprint($DBName);
// varprint($collationList);
// varprint($charsetList);
// die();

$arLog    = [];
$tblCount = 0;
if($Convert){

  //$connect->query("ALTER DATABASE `" . $DBName . "` COLLATE '" . $collate . "'"); //HeidiSQL
  $connect->query("ALTER DATABASE `" . $DBName . "` CHARACTER SET " . $charset . " COLLATE '" . $collate . "'");

  $resT = $connect->query("SHOW TABLES");
  while($row = $resT->fetch()){

    $table = $row['Tables_in_' . $DBName];

    $connect->query("ALTER TABLE `" . $table . "` CHARACTER SET " . $charset . " COLLATE " . $collate . ";");

    $arChangedSql = [];
    $resF         = $connect->query("SHOW FULL COLUMNS FROM `" . $table . "`");
    while($field = $resF->fetch()){

      preg_match("/^[a-z]+/i", $field['Type'], $match);

      if($match[0] && in_array($match[0], $arConvert)){

        $tblCollation = strpos($field['Collation'], '_bin') ? $charset . '_bin' : $collate;

        //$sq="ALTER TABLE `$data[0]` CHANGE `".$field['Field'].'` `'.$field['Field'].'` '.$field['Type']." CHARACTER SET $charset ".($collate==''?'':"COLLATE $collate")
        //.($field['Default']==''?'':($field['Default']=='NULL'?' DEFAULT NULL':' DEFAULT \''.mysql_escape_string($field['Default']).'\'')).($field['Null']=='YES'?' NULL ':' NOT NULL').($field['Comment']==''?'':' COMMENT \''.mysql_escape_string($field['Comment']).'\'').';';

        $sql = 'ALTER TABLE `' . $table . '` MODIFY `' . $field['Field'] . '` ' . $field['Type']
          . ' CHARACTER SET ' . $charset . ' COLLATE ' . $tblCollation
          . ($field['Null'] != 'YES' ? ' NOT ' : '') . ' NULL '
          . ($field['Default'] === null ? ($field['Null'] == 'YES' ? 'DEFAULT NULL' : '') : 'DEFAULT "' . $helper->forSql($field['Default']) . '"')
          . ($field['Comment'] == '' ? '' : ' COMMENT "' . $helper->forSql($field['Comment']) . '"')
          . ';';

        //echo "<pre>";print_r($sql);echo "</pre>";

        $arChangedSql[] = $sql;
        $connect->query($sql);
      }
      /*if($table == 'b_event_message' && $field['Field'] == 'ADDITIONAL_FIELD'){
        echo "<pre>";print_r($field);echo "</pre>";
      }*/
    }

    //if($table == 'b_event_message'){break;}

    //Результат конвертации
    $resN = $connect->query("SHOW TABLE STATUS LIKE '" . $table . "'");
    $rowN = $resN->fetch();

    $arLog[$table] = [
      'collate' => $rowN['Collation'],
      'sql'     => $arChangedSql,
    ];
    $tblCount++;
  }

  // Send Email after convertation
  if($bSendMail){

    $mailCharset     = 'UTF-8';
    $mailContentType = 'plain';

    $site = Bitrix\Main\SiteTable::getRowById(SITE_ID);
    $from = Bitrix\Main\Config\Option::get('main', 'email_from');

    $to = trim($site['EMAIL']);
    //$to = Main\Mail\Mail::encodeMimeString($to, $mailCharset);

    $subject = trim($site['NAME']);
    $message = 'Covert ' . $DBName . ' complete';

    $mailParams = [
      'TO'           => $to,
      'SUBJECT'      => $subject,
      'BODY'         => $message,
      'HEADER'       => [
        'From'       => $from,
        'Reply-To'   => $from,
        'Precedence' => 'bulk',
      ],
      'CHARSET'      => $mailCharset,
      'CONTENT_TYPE' => $mailContentType == "html" ? "html" : "plain",
      'MESSAGE_ID'   => '',
      'ATTACHMENT'   => [],
    ];

    Bitrix\Main\Mail\Mail::send($mailParams);
  }
}

#**********************************************************
#                    ПОСЛЕ КОНВЕРТАЦИИ
#**********************************************************
$arNewCollate = [];
$res          = $connect->query("SHOW VARIABLES WHERE Variable_name LIKE 'collation%';");
while($row = $res->fetch()){
  $arNewCollate[$row['Variable_name']] = $row['Value'];
}

$arNewCharset = [];
$res          = $connect->query("SHOW VARIABLES WHERE Variable_name LIKE 'character\_set\_%';");
while($row = $res->fetch()){
  if($row['Variable_name'] == 'character_set_filesystem' ||
    $row['Variable_name'] == 'character_set_system')
    continue;

  $arNewCharset[$row['Variable_name']] = $row['Value'];
}

#**********************************************************
#                           ВЫВОД
#**********************************************************
if($arNewCharset['character_set_database'] != $charset){
  $messError[] = 'База в кодировке = ' . $arNewCharset['character_set_database'];
}
else{
  $messOk[] = 'База в кодировке = ' . $arNewCharset['character_set_database'];
  $messOk[] = 'Всего таблиц: ' . $tblCount;
}

?>
<style>
  body{font:400 0.875rem/1.25rem "Courier New", Helvetica, Arial, sans-serif; color:#222;}
  table{border-collapse:collapse;border-spacing:0;margin-bottom:15px;font:inherit;}
  table td, table th{padding:8px 8px;border-bottom:1px solid #E5E5E5;}
  table th{text-align:left;}
  table thead th{vertical-align:bottom; font-size:1rem}
  table td{padding:4px 8px; vertical-align:top;}
  table tbody tr:nth-of-type(2n+1){background:#fafafa;}
  .alert{position:relative;padding:.75rem 1.25rem;margin-bottom:1rem;border:1px solid transparent;border-radius:.25rem;}
  .alert-success{color:#155724;background-color:#d4edda;border-color:#c3e6cb;}
  .alert-danger{color:#721c24;background-color:#f8d7da;border-color:#f5c6cb;}
  .btn{
    display:inline-block;
    font-weight:400;
    text-align:center;
    white-space:nowrap;
    vertical-align:middle;
    -webkit-user-select:none;
    -moz-user-select:none;
    -ms-user-select:none;
    user-select:none;
    border:1px solid transparent;
    padding:.375rem 2rem;
    font-size:1rem;
    line-height:1.5;
    border-radius:.25rem;
    cursor:pointer;
    transition:background-color .15s ease-in-out, border-color .15s ease-in-out, box-shadow .15s ease-in-out;
  }
  .btn-primary{color:#fff;background-color:#007bff;border-color:#007bff;}
  .btn-group-lg > .btn, .btn-lg{padding:.5rem 1rem; font-size:1.25rem; line-height:1.5;border-radius:.3rem;}
  .btn:focus, .btn:hover{text-decoration:none;}
  .btn-primary:hover{color:#fff;background-color:#0069d9;border-color:#0062cc;}
</style>

<form action="" method="post">
  <p>
    <label>
      <input type="checkbox" name="send_mail" value="Y"> Отправить E-mail
    </label>
  </p>
  <p>
    <button type="submit" name="Convert" value="Y" class="btn btn-primary">Начать конвертацию</button>
  </p>
</form>
<br>
<h2>## До конвертации ##</h2>
<? if(!empty($charsetList)): ?>
  <table>
    <thead>
    <tr>
      <th colspan="2">Кодировка сервера (character_set)</th>
    </tr>
    </thead>
    <tbody>
    <? foreach($charsetList as $key => $val): ?>
      <tr>
        <td><?=$key?></td>
        <td><?=$val?></td>
      </tr>
    <? endforeach; ?>
    </tbody>
  </table>
<? endif; ?>

<? if(!empty($collationList)): ?>
  <table>
    <thead>
    <tr>
      <th colspan="2">Cопоставление сервера (colation)</th>
    </tr>
    </thead>
    <tbody>
    <? foreach($collationList as $key => $val): ?>
      <tr>
        <td><?=$key?></td>
        <td><?=$val?></td>
      </tr>
    <? endforeach; ?>
    </tbody>
  </table>
<? endif; ?>

<? if(!empty($Convert)): ?>
  <h2>## После конвертации ##</h2>
  <? if(!empty($arNewCharset)): ?>
    <table>
      <thead>
      <tr>
        <th colspan="2">Кодировка сервера (character_set)</th>
      </tr>
      </thead>
      <tbody>
      <? foreach($arNewCharset as $key => $val): ?>
        <tr>
          <td><?=$key?></td>
          <td><?=$val?></td>
        </tr>
      <? endforeach; ?>
      </tbody>
    </table>
  <? endif; ?>

  <? if(!empty($arNewCollate)): ?>
    <table>
      <thead>
      <tr>
        <th colspan="2">Cопоставление (colation)</th>
      </tr>
      </thead>
      <tbody>
      <? foreach($arNewCollate as $key => $val): ?>
        <tr>
          <td><?=$key?></td>
          <td><?=$val?></td>
        </tr>
      <? endforeach; ?>
      </tbody>
    </table>
  <? endif; ?>

  <? if(!empty($messOk)): ?>
    <div class="alert alert-success"><?=implode('<br>', $messOk)?></div>
  <? endif ?>
  <? if(!empty($messError)): ?>
    <div class="alert alert-danger"><?=implode('<br>', $messError)?></div>
  <? endif ?>

  <? if(!empty($arLog)): ?>
    <? $j = 1; ?>
    <h2>#Лог конвертации</h2>
    <table>
      <thead>
      <tr>
        <th>#</th>
        <th>Таблица</th>
        <th>Кодировка</th>
        <th>SQL-запросы изменяемых полей</th>
      </tr>
      </thead>
      <tbody>
      <? foreach($arLog as $table => $log): ?>
        <tr>
          <td><?=$j++?></td>
          <td><?=$table?></td>
          <td><?=$log['collate']?></td>
          <td>
            <? if($log['sql']): ?>
              <pre><?=implode('<br>', $log['sql'])?></pre>
            <? endif; ?>
          </td>
        </tr>
      <? endforeach; ?>
      </tbody>
    </table>
  <? endif; ?>
<? endif; ?>
