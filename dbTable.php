<h1> Report </h1>
<pre>
<?php
// Implemented by Yvette Hernandez

// Connect to db
$db = new PDO('sqlite:ohweb.db');
$result_files = $db->prepare('SELECT pathname,exist,permissions,owner, maingroup,size,mtime,hash,bwwlist,reported FROM files WHERE reported= :reported');
$result_files->execute(array('reported'=>0));

print "<table border='0'>";
print "<tr><th>Pathname</th><th>Permissions</th><th>Owner</th><th>Maingroup</th><th>Size</th><th>ModTime</th><th>Hash</th></tr>";

foreach($result_files as $f)
{
    $result_report = $db->prepare('SELECT pathname,exist,permissions,owner,maingroup,size,mtime,hash,bwwlist,reported FROM report WHERE pathname= :pathname');
    $result_report->execute(array('pathname' => $f['pathname']));
    foreach($result_report as $r)
    {
        if($f['pathname'] != $r['pathname'] or $f['permissions'] != $r['permissions'] or $f['owner'] != $r['owner'] or $f['maingroup'] != $r['maingroup'] or $f['size'] != $r['size'] or $f['mtime'] != $r['mtime'] or $f['hash'] != $r['hash'])
        {
            print "<tr><td> last: ".$f['pathname']."</td>";
            print "<td>".$f['permissions']."</td>";
            print "<td>".$f['owner']."</td>";
            print "<td>".$f['maingroup']."</td>";
            print "<td>".$f['size']."</td>";
            print "<td>".$f['mtime']."</td>";
            print "<td>".$f['hash']."</td>";
            print "<tr><td> current: ".$r['pathname']."</td>";
            print "<td>".$r['permissions']."</td>";
            print "<td>".$r['owner']."</td>";
            print "<td>".$r['maingroup']."</td>";
            print "<td>".$r['size']."</td>";
            print "<td>".$r['mtime']."</td>";
            print "<td>".$r['hash']."</td>";
            print "</tr>\n";
        }
    }
}
print "</table>";

// close connection
$db = null;
?>
</pre>

