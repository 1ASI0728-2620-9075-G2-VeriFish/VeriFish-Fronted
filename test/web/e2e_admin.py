"""Real Azure browser smoke test. Credentials come from VERIFISH_TEST_ACCOUNTS.

Run against a debug build served at http://localhost:3000 using Playwright.
The first fixture account must be a dedicated ADMIN test account. This test
creates a farm when needed, a pond and a simulated IoT device; no actuator
commands are sent. Never use a production operator account as a fixture.
"""
import json
import os
import re
import time
from pathlib import Path

from playwright.sync_api import sync_playwright, expect


def run():
    accounts = json.loads(Path(os.environ['VERIFISH_TEST_ACCOUNTS']).read_text())
    user = accounts[0]
    device_code = 'TB2-' + user['username'] + '-' + str(int(time.time()))
    output = Path(os.environ.get('VERIFISH_EVIDENCE_DIR', 'build/evidence'))
    output.mkdir(parents=True, exist_ok=True)
    results = []
    with sync_playwright() as playwright:
        options = {}
        if os.environ.get('PLAYWRIGHT_CHROMIUM_EXECUTABLE'):
            options['executable_path'] = os.environ['PLAYWRIGHT_CHROMIUM_EXECUTABLE']
        browser = playwright.chromium.launch(**options)
        page = browser.new_page(viewport={'width': 1440, 'height': 1000})

        def screenshot(name):
            page.screenshot(path=str(output / name))

        def semantics():
            placeholder = page.locator('flt-semantics-placeholder')
            if placeholder.count():
                placeholder.dispatch_event('click')

        def type_in(field, value):
            field.click()
            page.wait_for_timeout(150)
            field.press('ControlOrMeta+A')
            field.press('Backspace')
            field.press_sequentially(value, delay=30)
            field.press('Tab')

        def login():
            type_in(page.locator('input').nth(0), user['username'])
            type_in(page.locator('input').nth(1), user['password'])
            page.get_by_role('button', name='Iniciar Sesión', exact=True).click()
            expect(page.get_by_text('Bienvenido, Prueba', exact=True)).to_be_visible(timeout=30000)

        try:
            page.goto('http://localhost:3000')
            page.locator('flutter-view').wait_for(timeout=30000)
            semantics()
            expect(page.get_by_role('button', name='Iniciar Sesión', exact=True)).to_be_visible()
            screenshot('exec-web-login.png')
            login()
            results.append('login real contra Azure: OK')
            if page.get_by_role('button', name='Crear Granja', exact=True).count():
                type_in(page.get_by_label('Nombre de la granja', exact=True), 'TB2 ' + user['username'])
                type_in(page.get_by_label('Dirección (opcional)', exact=True), 'Granja de pruebas TB2')
                page.get_by_role('button', name='Crear Granja', exact=True).click()
                expect(page.get_by_role('button', name='Iniciar Sesión', exact=True)).to_be_visible(timeout=30000)
                login()
                results.append('crear granja y renovar sesión: OK')
            page.get_by_role('button', name='Estanques', exact=True).click()
            expect(page.get_by_role('button', name='Nuevo Estanque', exact=True)).to_be_visible(timeout=30000)
            screenshot('exec-web-ponds.png')
            page.get_by_role('button', name='Nuevo Estanque', exact=True).click()
            expect(page.get_by_label('Volumen (m³)', exact=True)).to_be_visible()
            screenshot('exec-web-register-pond.png')
            type_in(page.get_by_label('Nombre', exact=True), 'Estanque TB2 navegador')
            type_in(page.get_by_label('Volumen (m³)', exact=True), '20')
            page.get_by_role('button', name='Crear', exact=True).click()
            expect(page.get_by_role('button', name=re.compile(r'^Estanque TB2 navegador')).first).to_be_visible(timeout=30000)
            results.append('registrar y listar estanque: OK')
            page.get_by_role('button', name='Equipos', exact=True).click()
            expect(page.get_by_role('button', name='Registrar Equipo', exact=True)).to_be_visible(timeout=30000)
            screenshot('exec-web-equipment.png')
            page.get_by_role('button', name='Registrar Equipo', exact=True).click()
            page.get_by_text('IOT NODE', exact=True).click()
            type_in(page.get_by_label('Nombre', exact=True), 'Nodo TB2 navegador')
            type_in(page.get_by_label('Código físico', exact=True), device_code)
            page.get_by_role('button', name='Registrar', exact=True).click()
            expect(page.get_by_label('Código físico', exact=True)).to_have_count(0, timeout=30000)
            results.append('registrar dispositivo IoT: OK')
            page.get_by_role('button', name='Registrar Equipo', exact=True).click()
            type_in(page.get_by_label('Nombre', exact=True), 'Nodo TB2 duplicado')
            type_in(page.get_by_label('Código físico', exact=True), device_code)
            with page.expect_response(lambda response:
                    response.request.method == 'POST' and '/equipment/iot-device' in response.url) as duplicate:
                page.get_by_role('button', name='Registrar', exact=True).click()
            if duplicate.value.status == 409:
                expect(page.get_by_text(re.compile('Ya existe un registro'))).to_be_visible(timeout=30000)
                results.append('rechazar dispositivo duplicado y conservar formulario: OK')
                page.get_by_role('button', name='Cancelar', exact=True).click()
            else:
                results.append('BLOCKED: backend duplicado devuelve ' + str(duplicate.value.status) + '; se esperaba 409')
                if duplicate.value.status >= 400:
                    page.get_by_role('button', name='Cancelar', exact=True).click()
                else:
                    expect(page.get_by_label('Código físico', exact=True)).to_have_count(0, timeout=30000)
            page.get_by_role('button', name=re.compile(r'^Nodo TB2 navegador')).first.click()
            page.get_by_role('button', name='Linkear con Estanque', exact=True).click()
            page.get_by_text('Elige un estanque', exact=True).click()
            page.get_by_role('menuitem', name='Estanque TB2 navegador', exact=True).first.click()
            page.get_by_role('button', name='Linkear', exact=True).click()
            expect(page.get_by_text('Seleccionar Estanque', exact=True)).to_have_count(0, timeout=30000)
            results.append('vincular equipo a estanque: OK')
            screenshot('exec-web-equipment.png')
            page.get_by_role('button', name='Notificaciones', exact=True).click()
            expect(page.get_by_text('Alertas y eventos del sistema', exact=True)).to_be_visible(timeout=30000)
            screenshot('exec-web-notifications.png')
            results.append('consultar notificaciones: OK')
            page.reload()
            page.locator('flutter-view').wait_for(timeout=30000)
            semantics()
            expect(page.get_by_text('Alertas y eventos del sistema', exact=True)).to_be_visible(timeout=30000)
            results.append('restaurar sesión y recargar ruta: OK')
            page.evaluate("localStorage.setItem('flutter.yaku_access_token', JSON.stringify('invalid-test-token'))")
            page.reload()
            page.locator('flutter-view').wait_for(timeout=30000)
            semantics()
            expect(page.get_by_role('button', name='Iniciar Sesión', exact=True)).to_be_visible(timeout=30000)
            results.append('401 real limpia sesión y vuelve al login: OK')
            login()
            page.get_by_role('button', name='Cerrar sesión', exact=True).click()
            expect(page.get_by_role('button', name='Iniciar Sesión', exact=True)).to_be_visible(timeout=30000)
            results.append('cerrar sesión explícitamente: OK')
        except Exception:
            screenshot('web-flow-failure.png')
            print(page.locator('body').aria_snapshot()[:4000])
            raise
        finally:
            (output / 'web-browser-results.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
            print(json.dumps(results, ensure_ascii=False))
            browser.close()
    if any(result.startswith('BLOCKED:') for result in results):
        raise SystemExit(1)


if __name__ == '__main__':
    run()
