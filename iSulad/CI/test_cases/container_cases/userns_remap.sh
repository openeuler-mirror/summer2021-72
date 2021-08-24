#!/bin/bash
#
# attributes: isulad user namespaces remap
# concurrent: YES
# spend time: 4

#######################################################################
##- @Copyright (C) Huawei Technologies., Ltd. 2020. All rights reserved.
# - iSulad licensed under the Mulan PSL v2.
# - You can use this software according to the terms and conditions of the Mulan PSL v2.
# - You may obtain a copy of Mulan PSL v2 at:
# -     http://license.coscl.org.cn/MulanPSL2
# - THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# - IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# - PURPOSE.
# - See the Mulan PSL v2 for more details.
##- @Description:CI
##- @Author: liuyuji
##- @Create: 2020-08-20
#######################################################################

source ../helpers.sh

LCR_ROOT_PATH="/var/lib/isulad/100000.100000/engines/lcr"

function do_test_t()
{
    msg_info "test userns_remap starting..."

	check_valgrind_log
	[[ $? -ne 0 ]] && msg_err "${FUNCNAME[0]}:${LINENO} - memory leak before current testcase, please check...." && return ${FAILURE}

	start_isulad_without_valgrind --userns-remap="100000:100000:65535"

    containername=test_create
    containerid=`isula run -itd --name $containername busybox`
    fn_check_eq "$?" "0" "create failed"
    testcontainer $containername running
    
    cat "$LCR_ROOT_PATH/$containerid/config"  | grep "lxc.idmap = u 0 100000 65535"
    fn_check_eq "$?" "0" "create failed"

    cat "$LCR_ROOT_PATH/$containerid/config"  | grep "lxc.idmap = g 0 100000 65535"
    fn_check_eq "$?" "0" "create failed"
    
    isula rm -f $containername
    fn_check_eq "$?" "0" "rm failed"

    isula inspect $containername
    fn_check_ne "$?" "0" "inspect should failed"
    
    containerid=`isula run -itd --name $containername --userns="host" busybox`
    fn_check_eq "$?" "0" "create failed"
    testcontainer $containername running
    
    cat "$LCR_ROOT_PATH/$containerid/config"  | grep "lxc.idmap = u 0 100000 65535"
    fn_check_ne "$?" "0" "uidmap should not exist"

    cat "$LCR_ROOT_PATH/$containerid/config"  | grep "lxc.idmap = g 0 100000 65535"
    fn_check_ne "$?" "0" "gidmap should not exist"
    
    isula rm -f $containername
    fn_check_eq "$?" "0" "rm failed"

    isula inspect $containername
    fn_check_ne "$?" "0" "inspect should failed"
    
    return $TC_RET_T
}

ret=0

do_test_t
if [ $? -ne 0 ];then
    let "ret=$ret + 1"
fi
stop_isulad_without_valgrind

show_result $ret "user namespaces remap"
