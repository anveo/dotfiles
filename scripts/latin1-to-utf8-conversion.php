<?php
/**
 * A script to convert database collation/charset from latin1 to utf8-general-ci
 *
 * @copyright Copyright 2003-2011 Zen Cart Development Team
 * @license http://www.zen-cart.com/license/2_0.txt GNU Public License V2.0
 * @version $Id: latin1-to-utf8-conversion.php 19000 2011-07-02 08:22:29Z drbyte $
 *
 * @copyright Adapted from http://stackoverflow.com/questions/105572/
 * 2011-06-01 DrByte www.zen-cart.com - Added support for multi-key and partial-length indices
 * 2011-06-01 DrByte www.zen-cart.com - Added support for table prefixes
 * 2011-06-01 DrByte www.zen-cart.com - Added performance metrics and visual improvements
 * 2011-07-01 DrByte www.zen-cart.com - Added support for proper handling of column defaults and proper null handling
 * 2011-07-02 DrByte www.zen-cart.com - Added support for variable-length char fields
 *
 *
 */

$username = "";
$password = "";
$db       = "";
$host     = "localhost";
$prefix   = '';


// these are the recommended settings:
$target_charset = "utf8";
$target_collate = "utf8_general_ci";

/////// DO NOT CHANGE BELOW THIS LINE ////////

// Begin processing
$timer = time();
echo "<strong>Database Charset/Collation Conversion</strong><br><br>Converting tables " . ($prefix == '' ? '' : 'with prefix ['.$prefix.'] ') . "in database [$db] to $target_collate <br><br>This may take awhile. Please wait ... <br><pre>";
if ($username == "your_database_username_here") die('<span style="color: red; font-weight: bold">Error: Database credentials required. Please edit this PHP file and supply your DB username/password/db-name details.</span>');
$conn = mysql_connect($host, $username, $password);
mysql_select_db($db, $conn);
$tabs = array();
$t = $i = 0;
$res = mysql_query("SHOW TABLES");
printMySqlErrors();
while (($row = mysql_fetch_row($res)) != null)
{
  if ($prefix == '')
  {
    $tabs[] = $row[0];
  } else if (substr($row[0], 0,strlen($prefix)) == $prefix) {
    $tabs[] = $row[0];
  }
}
// now, fix tables
foreach ($tabs as $tab)
{
  $t++;
  echo "\nProcessing table [{$tab}]:\n";
  $res = mysql_query("show index from {$tab}");
  printMySqlErrors();
  $indices = array();
  while (($row = mysql_fetch_array($res)) != null)
  {
    if ($row[2] != "PRIMARY")
    {
      if (sizeof($indices) == 0 || $indices[sizeof($indices) - 1]['name'] != $row[2])
      {
        $indices[] = array("name" => $row[2] , "unique" => (int)!($row[1] == "1") , "col" => $row[4] . ($row[7] < 1 ? '' : "($row[7])"));
        mysql_query("ALTER TABLE {$tab} DROP INDEX {$row[2]}");
        printMySqlErrors();
        echo "Dropped index {$row[2]}. Unique: " . ($row[1] == '1' ? 'No' : 'Yes') . "\n";
      } else
      {
        $indices[sizeof($indices) - 1]["col"] .= ', ' . $row[4] . ($row[7] < 1 ? '' : "($row[7])");
      }
    }
  }
  $res = mysql_query("DESCRIBE {$tab}");
  printMySqlErrors();
  while (($row = mysql_fetch_array($res)) != null)
  {
    $name = $row[0];
    $type = $row[1];
    $allownull = (strtoupper($row[2]) == 'YES') ? 'NULL' : 'NOT NULL';
    $defaultval = (trim($row[4]) == '') ? '' : "DEFAULT '{$row[4]}'";
    $set = false;
    if (preg_match("/^varchar\((\d+)\)$/i", $type, $mat))
    {
      $size = $mat[1];
      mysql_query("ALTER TABLE {$tab} MODIFY {$name} VARBINARY({$size}) {$allownull} {$defaultval}");
      printMySqlErrors();
      mysql_query("ALTER TABLE {$tab} MODIFY {$name} VARCHAR({$size}) CHARACTER SET {$target_charset} {$allownull} {$defaultval}");
      printMySqlErrors();
      $set = true;
      echo "Altered field {$name} on {$tab} from type {$type}\n";
    } else
      if (preg_match("/^char\((\d+)\)$/i", $type, $mat))
      {
        $size = $mat[1];
        mysql_query("ALTER TABLE {$tab} MODIFY {$name} BINARY({$size}) {$allownull} {$defaultval}");
        printMySqlErrors();
        mysql_query("ALTER TABLE {$tab} MODIFY {$name} CHAR({$size}) CHARACTER SET {$target_charset} {$allownull} {$defaultval}");
        printMySqlErrors();
        $set = true;
        echo "Altered field {$name} on {$tab} from type {$type}\n";
      } else
        if (! strcasecmp($type, "TINYTEXT"))
        {
          mysql_query("ALTER TABLE {$tab} MODIFY {$name} TINYBLOB {$allownull} {$defaultval}");
          printMySqlErrors();
          mysql_query("ALTER TABLE {$tab} MODIFY {$name} TINYTEXT CHARACTER SET {$target_charset} {$allownull} {$defaultval}");
          printMySqlErrors();
          $set = true;
          echo "Altered field {$name} on {$tab} from type {$type}\n";
        } else
          if (! strcasecmp($type, "MEDIUMTEXT"))
          {
            mysql_query("ALTER TABLE {$tab} MODIFY {$name} MEDIUMBLOB {$allownull} {$defaultval}");
            printMySqlErrors();
            mysql_query("ALTER TABLE {$tab} MODIFY {$name} MEDIUMTEXT CHARACTER SET {$target_charset} {$allownull} {$defaultval}");
            printMySqlErrors();
            $set = true;
            echo "Altered field {$name} on {$tab} from type {$type}\n";
          } else
            if (! strcasecmp($type, "LONGTEXT"))
            {
              mysql_query("ALTER TABLE {$tab} MODIFY {$name} LONGBLOB {$allownull} {$defaultval}");
              printMySqlErrors();
              mysql_query("ALTER TABLE {$tab} MODIFY {$name} LONGTEXT CHARACTER SET {$target_charset} {$allownull} {$defaultval}");
              printMySqlErrors();
              $set = true;
              echo "Altered field {$name} on {$tab} from type {$type}\n";
            } else
              if (! strcasecmp($type, "TEXT"))
              {
                mysql_query("ALTER TABLE {$tab} MODIFY {$name} BLOB {$allownull} {$defaultval}");
                printMySqlErrors();
                mysql_query("ALTER TABLE {$tab} MODIFY {$name} TEXT CHARACTER SET {$target_charset} {$allownull} {$defaultval}");
                printMySqlErrors();
                $set = true;
                echo "Altered field {$name} on {$tab} from type {$type}\n";
              }
    if ($set) {
      mysql_query("ALTER TABLE {$tab} MODIFY {$name} COLLATE {$target_collate}");
      echo "Table altered: {$tab}\n";
    }
  }
  // re-build indices..
  foreach ($indices as $index)
  {
    $i++;
    mysql_query("CREATE " . ($index["unique"] ? "UNIQUE " : '') . "INDEX {$index["name"]} ON {$tab} ({$index["col"]})");
    printMySqlErrors();
    echo "Created index {$index["name"]} on {$tab} ({$index["col"]}). Unique: " . ($row[1] == '1' ? 'Yes' : 'No') . "\n";
  }
  // set default collate
  mysql_query("ALTER TABLE {$tab} DEFAULT CHARACTER SET {$target_charset} COLLATE {$target_collate}");
}
// set database charset
mysql_query("ALTER DATABASE {$db} DEFAULT CHARACTER SET {$target_charset} COLLATE {$target_collate}");
mysql_close($conn);
echo "</pre>\n";
$timer_diff = time() - $timer;
echo $t . ' Tables processed, ' . $i . ' Indexes processed, ' . $timer_diff . ' seconds elapsed time.';
echo '<br><br><br><span style="color:red;font-weight:bold">NOTE: This conversion script should now be DELETED from your server for security reasons!!!!!</span><br><br><br>';

function printMySqlErrors()
{
  if (mysql_errno())
  {
    echo '<span style="color: red; font-weight: bold">MySQL Error: ' . mysql_error() . '</span>' . "\n";
  }
}
