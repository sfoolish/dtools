import sys
import subprocess
import time

import log as logging

LOG = logging.getLogger("galera_bootstrap")

def exec_cmd(cmd):
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=None,
        shell=True)
    output, err = process.communicate()
    returncode = process.returncode
    LOG.info("cmd: %s" % cmd)
    LOG.info("output: %s" % output)
    LOG.info("err: %s" % err)
    LOG.info("returncode: %s" % returncode)
    return output, err, returncode

def get_wsrep_cluster_address():
    cmd = "cat /etc/mysql/conf.d/wsrep.cnf | grep wsrep_cluster_address | awk -F'/' '{print $3}'"
    output = exec_cmd(cmd)[0]

    return output.strip().split(",")

def _wait_node_ok(addr):
    cmd = "ssh root@%s uname 2>/dev/null" % (addr)
    count = 600
    while count > 0:
        output, err, _ = exec_cmd(cmd)
        if "Linux" in output:
            return True
        count = count - 1
    return False

def wait_nodes_ok(addrs):
    for addr in addrs:
        if not _wait_node_ok(addr):
            return False
    return True

def _is_mysql_reachable(addr):
    cmd = "ssh root@%s \"mysql -e 'use pets;' \" 2>/dev/null" % (addr)
    output, err, returncode = exec_cmd(cmd)
    if returncode != 0:
        return False
    return True

def is_all_mysql_reachable(addrs):
    unreachable_addrs = []
    for addr in addrs:
        if not _is_mysql_reachable(addr):
            unreachable_addrs.append(addr)
    if len(unreachable_addrs) != 0:
        return False, unreachable_addrs
    return True, None

def _killall_mysql(addr):
    cmd = "ssh root@%s service mysql stop 2>/dev/null;" % (addr)
    cmd += "ssh root@%s killall -9 mysqld 2>/dev/null;" % (addr)

    exec_cmd(cmd)

def kill_all_mysql(addrs):
    for addr in addrs:
        _killall_mysql(addr)

def _get_database_seqno(addr):
    cmd = "ssh root@%s mysqld --wsrep-recover 2>&1 | grep -o \"Recovered position.*\" | awk -F':' '{print $3}' 2>/dev/null;" % (addr)
    output, err, returncode = exec_cmd(cmd)
    return int(output)

def get_bootstrap_node_addr(addrs):
    max_seqno = 0
    bootstrap_addr=""

    for addr in addrs:
        seqno = _get_database_seqno(addr)
        if seqno > max_seqno:
            max_seqno = seqno
            bootstrap_addr = addr

    return bootstrap_addr

def _do_bootstrap_galera_cluster(addr):
    cmd = "ssh root@%s echo 'safe_to_bootstrap: 1' >> /var/lib/mysql/grastate.dat 2>/dev/null;" % (addr)
    cmd += "ssh root@%s service mysql bootstrap 2>/dev/null;" % (addr)
    output, err, returncode = exec_cmd(cmd)
    return True

def do_bootstrap_galera_cluster(addr):
    count = 3
    while count > 0:
        _killall_mysql(addr)
        _do_bootstrap_galera_cluster(addr)
        if _is_mysql_reachable(addr):
            break;
        count -= 1
    return count > 0

def _do_join_galera_cluster(addr):
    cmd = "ssh root@%s service mysql restart 2>/dev/null;" % (addr)
    exec_cmd(cmd)

def do_join_galera_cluster(addr):
    count = 3
    while count > 0:
        _killall_mysql(addr)
        _do_join_galera_cluster(addr)
        if _is_mysql_reachable(addr):
            break;
        count -= 1
    return count > 0

def recover_galera_cluster(addrs):
    status, unreachable_addrs = is_all_mysql_reachable(addrs)
    if status == True:
        return True
    if len(unreachable_addrs) != len(addrs):
        print "ERROR %r, %r" % (addrs, unreachable_addrs)
        return False

    kill_all_mysql(addrs)
    bootstrap_addr = get_bootstrap_node_addr(addrs)
    do_bootstrap_galera_cluster(bootstrap_addr)
    for addr in addrs:
        if addr == bootstrap_addr:
            continue
        do_join_galera_cluster(addr)

    status, unreachable_addrs = is_all_mysql_reachable(addrs)
    print "status: %r, %r" % (status, unreachable_addrs)
    return status

def is_ip_reachable(ip):
    cmd = "ping -c 2 %s" % ip
    output, err, returncode = exec_cmd(cmd)
    if returncode != 0:
        return False
    return True

def get_external_vip_address():
    cmd = "cat /etc/keepalived/keepalived.conf | grep 'dev.*external' | awk -F'/' '{print $1}'"
    output, err, returncode = exec_cmd(cmd)
    addr = output.strip().split(",")[0]
    return addr

def _restart_keepalived(addr):
    cmd = "ssh root@%s service keepalived restart 2>/dev/null" % (addr)
    exec_cmd(cmd)

def recover_keepalived(addrs):
    count = 3
    addr = get_external_vip_address()
    while count > 0:
        if is_ip_reachable(addr):
            break
        for addr in addrs:
            _restart_keepalived(addr)
        if is_ip_reachable(addr):
            break
        count -= 1
    return count > 0

def _restart_ceph_mon(addr):
    cmd = "ssh root@%s service ceph-mon restart 2>/dev/null" % (addr)
    exec_cmd(cmd)

def recover_ceph_mon(addrs):
    for addr in addrs:
        _restart_ceph_mon(addr)

def main():
    addrs = get_wsrep_cluster_address()
    print wait_nodes_ok(addrs)
    time.sleep(30)
    print recover_galera_cluster(addrs)
    #print recover_keepalived(addrs)
    #recover_ceph_mon(addrs)

if __name__ == "__main__":
    main()

