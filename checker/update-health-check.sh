#!/usr/bin/env ash

rconcmd() {
  local adminpass="$(cat $ADMIN_PASS)"
  local rconport="${RCON_PORT:-25575}"
  local ip="${SERVER:-palworld-server}"

  if [ -z "$adminpass" ]; then
    echo "ServerAdminPassword is empty - unable to execute RCON command"
    return 1
  elif [[ "$adminpass" =~ [?\177-\377] ]]; then
    echo "ServerAdminPassword contains invalid characters"
    return 1
  fi
  perl -MSocket -e '
    sub sendpkt {
      my ($sock, $reqid, $reqtype, $body) = @_;
      my $packet = pack("VVV", length($body) + 10, $reqid, $reqtype) . $body . "\0\0";
      send($sock, $packet, 0) or die "Error sending command to server: $!";
    }

    sub recvpkt {
      my ($sock) = @_;
      my $data = "";
      recv($sock, $data, 12, 0);
      die "Empty response" if length($data) == 0;
      my ($pktlen, $resid, $restype) = unpack("VVV", $data);
      recv($sock, $data, $pktlen - 8, 0);
      return ($resid, $restype, substr($data, 0, $pktlen - 10));
    }

    sub auth {
      my ($sock, $password) = @_;
      my $reqid = 1;
      sendpkt($sock, $reqid, 3, $password);
      my ($resid, $restype, $rcvbody) = recvpkt($sock);
      die "Authentication failed" if $resid == -1 or $resid == 0xFFFFFFFF;
    }

    my $port = $ARGV[0];
    my $ipaddr = $ARGV[1];
    my $password = $ARGV[2];
    my $command = $ARGV[3];
    socket(my $socket, PF_INET, SOCK_STREAM, 0);
    setsockopt($socket, SOL_SOCKET, SO_RCVTIMEO, pack("i4", 30, 0, 0, 0));
    my $sockaddr = pack_sockaddr_in($port, inet_aton($ipaddr));
    connect($socket, $sockaddr) or die "Error connecting to server: $!";
    auth($socket, $password);
    sendpkt($socket, 2, 2, $command);
    my ($resid, $restype, $rcvbody) = recvpkt($socket);
    if ($rcvbody eq "Server received, But no response!! \n ") {
      print "Command processed\n";
    } else {
      print "\"", $rcvbody, "\"\n";
    }
    ' "$rconport" "$ip" "$adminpass" "$1"
}


INSTALLED_BUILD=$(cat /data/steamapps/appmanifest_${APP_ID}.acf | grep -Po "^\s*\"buildid\"\s*\K\"(.*?)\"" | tr -d '"')
LATEST_BUILD=$(curl -s -X GET "https://api.steamcmd.net/v1/info/${APP_ID:-2394010}" | grep -Po "^.*branches.*public\": {\"buildid\":\s\K\"[0-9]*\"" | tr -d '"')

echo "INSTALLED_BUILD=$INSTALLED_BUILD"
echo "LATEST_BUILD=$LATEST_BUILD"
RESTART=0
REASON=""

if [ "${INSTALLED_BUILD:-0}" -eq "${LATEST_BUILD:-0}" ]; then
    echo "Latest version is installed!"
else
    echo "Update found!"
    REASON="Game update available"
    RESTART=1
fi

docker_health=$(docker container inspect -f '{{.State.Health.Status}}' ${SERVER:-palworld-server})

if [ "$docker_health" = "healthy" ]; then
  echo "Container is healthy"
else
  echo "Container is not healthy"
  RESTART=1
  REASON="Container health"
fi

PLAYERS_CONNECTED=0
if [ "$RESTART" -eq 1 ]; then
  conn_response=$(rconcmd ShowPlayers | tr -d '"')
  if [ -z "${conn_response##*"name,playeruid,steamid"*}" ]; then
    echo "$conn_response"
    if [ "$(echo $conn_response | tr ' ' '\n' | wc -l)" -ge "2" ]; then
      echo "Players connected"
      PLAYERS_CONNECTED=1
    fi
  fi
  echo "$PLAYERS_CONNECTED"
  message=$(echo "Server restarting in 10 minutes: $REASON" | tr " "  "_")
  if [ "$PLAYERS_CONNECTED" -eq "1" ]; then
    rconcmd "shutdown 600 $message"
  else
    rconcmd "shutdown"
  fi
fi
exit 0;

