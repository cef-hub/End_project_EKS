import json
from flask import Flask, jsonify
import psutil
import platform
from flask import send_from_directory

app = Flask(__name__)

@app.route('/disk_io_counters', methods=['GET'])
def get_disk_io_counters():
    io_dict = psutil.disk_io_counters(perdisk=True)
    io_dict_end = {}
    for key, value in io_dict.items():
        io_list = (key, value)
        current_item = str(io_list[1])
        current_physical_drive = str(io_list[0])
        current_item = current_item.replace('sdiskio(', '').replace(')', '').replace('=',' : ').replace('read_merged_count', '"read_merged_count"').replace('write_merged_count', '"write_merged_count"').replace('busy_time', '"busy_time"')
        current_item = current_item.replace('read_count', '"read_count"').replace('write_count', '"write_count"').replace('read_bytes', '"read_bytes"').replace('write_bytes', '"write_bytes"').replace('read_time', '"read_time"').replace('write_time', '"write_time"')
        current_item = '{' + f'{current_item}' + '}'
        io_dict_end[f'{key}'] = json.loads(current_item)
    return jsonify(io_dict_end)

@app.route('/connections', methods=['GET'])
def get_connections():
    pid_list = []
    connections_dict = {}
    connections_list = []
    for pid in psutil.pids():
        try:
            connections_list = []
            process_name = psutil.Process(pid).name()
            pid_conncetions = psutil.Process(pid).connections()
            connections_dict[f'process: {process_name}({pid})'] = ''
            for item in pid_conncetions:
                connections_list.append(f'{item}')
            connections_dict[f'process: {process_name}({pid})'] = connections_list
        except psutil.NoSuchProcess:
            pass
        except RuntimeError:
            pass
    return jsonify({f'connection': connections_dict})

@app.route('/process', methods=['GET'])
def get_process():
    process_list = []
    iter = 0
    cur_process = ''
    mem_total = f'MEM Total: {psutil.virtual_memory().total / (1024 ** 3):.2f}G'
    for pid in psutil.pids():
        iter += 1
        try:
            test_list = []
            for i in range(10):
                p = psutil.Process(pid)
                p_cpu = p.cpu_percent(interval=0.1)
                test_list.append(p_cpu)
            average = round(float(sum(test_list)) / len(test_list) / psutil.cpu_count(), 2)
            process_name = psutil.Process(pid).name()
            process_mem = round(psutil.Process(pid).memory_percent(), 2)
            process_list.append(f'process: {process_name}({pid}), CPU usage: {average}%, MEM usage: {process_mem}%')
        except psutil.NoSuchProcess:
            pass
        except RuntimeError:
            pass
        # print(f'iter: {iter}')
        # if iter > 10:
        #     break
    return jsonify({'MEM Total: ': mem_total, 'All Process: ': process_list})

@app.route('/download/subscriber', methods=['GET', 'POST'])
def download():
    return send_from_directory(directory=r'D:\Download', path='nsi.json')

@app.route('/info', methods=['GET'])
def get_info_api():
    api_info = '''
    Запустив этот код, мы можем получить информацию о компьютере, IP адресе, свободном месте на диске, загрузке ЦПУ
и оперативной памяти, используя следующие запросы:

GET http://localhost:5555/computer_info
GET http://localhost:5555/ip_address
GET http://localhost:5555/disk_drive
GET http://localhost:5555/disk_io_counters
GET http://localhost:5555/cpu_usage
GET http://localhost:5555/cpu_count
GET http://localhost:5555/users
GET http://localhost:5555/process
GET http://localhost:5555/sensors_temperatures
GET http://localhost:5555/memory
GET http://localhost:5555/download/subscriber
    '''
    return api_info

@app.route('/computer_info', methods=['GET'])
def get_computer_info():
    OS = platform.platform()
    kind_os = platform.system()
    release = platform.release()
    version = platform.version()
    name_computer = platform.node()
    return jsonify({'computer_name': name_computer, 'computer_platform': kind_os, 'OS_release': release, 'OS_version:' : version})

@app.route('/users', methods=['GET'])
def get_users():
    user_list = psutil.users()
    user_dict = {}
    user_dict['Operating_System'] = platform.uname()
    for id, item in enumerate(user_list):
        cur_name = item.name
        cur_terminal = item.terminal
        cur_host = item.host
        cur_started = item.started
        cur_pid = item.pid
        user_dict[f'user{id + 1}'] = f'Name:{cur_name}, ' + f'Logging_time:{cur_started}, ' + f'Host:{cur_host}, ' + f'Terminal:{cur_terminal}, ' + f'Pid_process:{cur_pid}'
    return jsonify(user_dict)

@app.route('/ip_address', methods=['GET'])
def get_ip_address():
    end_ip_string = ''
    list_net = []
    net_if_addrs = psutil.net_if_addrs()
    for key in psutil.net_if_addrs().keys():
        list_net = [*psutil.net_if_addrs()]
    last_net = list_net[len(list_net) - 1]
    if platform.system() == 'Windows':
        template = "'ip_address_[name_net]': psutil.net_if_addrs()['[name_net]'][1].address, 'netmask_[name_net]': psutil.net_if_addrs()['[name_net]'][1].netmask"
    else:
        template = "'ip_address_[name_net]': psutil.net_if_addrs()['[name_net]'][0].address, 'netmask_[name_net]': psutil.net_if_addrs()['[name_net]'][0].netmask"
    for item in list_net:
        now_string = template.replace('[name_net]', f'{item}') + ','
        end_ip_string = end_ip_string + now_string
        if item == last_net:
            end_ip_string = end_ip_string[:-1]
    end_ip_string = '{' + end_ip_string + '}'
    return jsonify(eval(end_ip_string))

@app.route('/sensors_temperatures', methods=['GET'])
def sensors_temperatures():
    return psutil.sensors_temperatures(fahrenheit=False)

@app.route('/disk_drive', methods=['GET'])
def get_disk_drive():
    disks = psutil.disk_partitions()
    disks_device = []
    disks_map = []
    disk_info = []
    disks_mountpoint = []
    disks_usage = {}
    disks_usage_end = {}
    cur_disk = ''
    for item in disks:
        cur_disk = item.opts
        cur_mountpoint = item.mountpoint
        if cur_disk !='removable' and cur_disk !='cdrom':
            disks_mountpoint.append(f'{item}')
            disks_device.append(f'{item}')
            disks_usage[f'{cur_mountpoint}'] = f'{psutil.disk_usage(cur_mountpoint)}'
    index = 0
    for key, val in disks_usage.items():
        val = val[11:-1]
        disks_map.append(key)
        disk_info.append(val)
        disks_usage_end[key] = disk_info[index]
        index += 1
    return jsonify({'disks': disks_usage_end})

@app.route('/cpu_usage', methods=['GET'])
def get_cpu_usage():
    cpu_ussage = '''    ctx_switches: number of context switches (voluntary + involuntary) since boot.
    interrupts: number of interrupts since boot.
    soft_interrupts: number of software interrupts since boot. Always set to 0 on Windows and SunOS.
    syscalls: number of system calls since boot. Always set to 0 on Linux.'''
    cpu_ussage_list = []
    cpu_ussage_list = cpu_ussage.split('\n')
    cpu_freq = {}
    cpu_freq = psutil.cpu_freq()
    return jsonify({'cpu_usage %': psutil.cpu_percent(), 'ctx_switches': psutil.cpu_stats().ctx_switches,'interrupts': psutil.cpu_stats().interrupts,'soft_interrupts': psutil.cpu_stats().soft_interrupts,'syscalls': psutil.cpu_stats().syscalls, 'cpu_stats': cpu_ussage_list, 'cpu_frequency' : {'current': round(cpu_freq.current,2),'min': round(cpu_freq.min,2),'max': round(cpu_freq.max,2)}})

@app.route('/cpu_count', methods=['GET'])
def get_cpu_count():
    return jsonify({'cpu_count': psutil.cpu_count()})

@app.route('/memory', methods=['GET'])
def get_memory():
    mem = psutil.virtual_memory()
    mem_str = str(round(mem.available / 1024 / 1024, 2)) + 'MB'
    return jsonify({'memory_total MB': round(psutil.virtual_memory().total / 1024 /1024, 2), 'memory_percent_usage %': psutil.virtual_memory().percent, 'memory_used MB': round(psutil.virtual_memory().used / 1024 /1024, 2), 'memory_free MB': round(psutil.virtual_memory().free / 1024 /1024, 2)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5555)


"""
Запустив этот код, мы можем получить информацию о компьютере, IP адресе, свободном месте на диске, загрузке ЦПУ
и оперативной памяти, используя следующие запросы:

GET http://localhost:5555/computer_name
GET http://localhost:5555/ip_address
GET http://localhost:5555/disk_drive
GET http://localhost:5555/disk_io_counters
GET http://localhost:5555/cpu_usage
GET http://localhost:5555/cpu_count
GET http://localhost:5555/users
GET http://localhost:5555/process
GET http://localhost:5555/sensors_temperatures
GET http://localhost:5555/memory
GET http://localhost:5555/info
GET http://localhost:5555/download/subscriber

Мы можем использовать библиотеку requests для отправки запросов на этот REST сервис.

Например, мы можем получить информацию об имени компьютера, используя следующий код:

import requests
response = requests.get('http://localhost:5555/computer_name')
print(response.json()['computer_name'])
"""

