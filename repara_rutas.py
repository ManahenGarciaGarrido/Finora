import os

def fix_lcov(path, prefix):
    if not os.path.exists(path): return
    print(f"Reparando {path}...")
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    with open(path, 'w', encoding='utf-8') as f:
        for line in lines:
            if line.startswith('SF:'):
                # Caso especial: SF:C:\Users\... o SF:finora_frontend/lib/...
                # Queremos que quede como SF:lib/... o SF:routes/...
                fixed = line.replace(f'SF:{prefix}/', 'SF:').replace('\\', '/')
                f.write(fixed)
            else:
                f.write(line)

def fix_xml(path):
    if not os.path.exists(path): return
    print(f"Reparando {path}...")
    with open(path, 'r', encoding='utf-8') as f:
        data = f.read()
    # Quitamos el prefijo de la carpeta en los atributos filename
    fixed_data = data.replace('filename="finora_ai/', 'filename="')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(fixed_data)

# Ejecutar reparaciones
fix_lcov('finora_frontend/coverage/lcov.info', 'finora_frontend')
fix_lcov('finora_backend/coverage/lcov.info', 'finora_backend')
fix_xml('finora_ai/coverage.xml')
print("✅ Rutas sincronizadas con el projectBaseDir de SonarQube.")