import time
from os.path import dirname, join

import pytest
from selenium.webdriver.common.keys import Keys
from syncloudlib.integration.hosts import add_host_alias_by_ip
from syncloudlib.integration.screenshots import screenshots

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, data_dir, ui_mode):
    def module_teardown():
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.run_ssh('cp /var/log/syslog {0}/syslog.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        app_log_dir = join(artifact_dir, 'log')
        device.scp_from_device('{0}/*'.format(TMP_DIR), app_log_dir)
        device.scp_from_device('{0}/log/*'.format(data_dir), app_log_dir)
    request.addfinalizer(module_teardown)


def test_start(module_setup, app, device_host, domain):
    add_host_alias_by_ip(app, domain, device_host)


def test_web(driver, app_domain, ui_mode, device_user, device_password, screenshot_dir):

    driver.get("https://{0}".format(app_domain))
    
    time.sleep(2)
    screenshots(driver, screenshot_dir, 'login-' + ui_mode)

    user = driver.find_element_by_id("name")
    user.send_keys(device_user)
    password = driver.find_element_by_id("password")
    password.send_keys(device_password)
   
    screenshots(driver, screenshot_dir, 'login-filled-' + ui_mode)
  
    password.send_keys(Keys.RETURN)

    time.sleep(10)
    screenshots(driver, screenshot_dir, 'login_progress-' + ui_mode)
    time.sleep(10)
    
    screenshots(driver, screenshot_dir, 'main-' + ui_mode)
    
