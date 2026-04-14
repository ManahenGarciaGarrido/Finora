import os

def fix_file(file_path, old_prefix, new_prefix="SF:"):
    if not os.path.exists(file_path):
        print(f"⚠️  No se encontró: {file_path}")
        return
    
    print(f"🔧 Reparando rutas en: {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Reparar separadores de Windows y quitar prefijos de carpeta
    # SF:finora_frontend/lib/... -> SF:lib/...
    fixed_content = content.replace('\\', '/')
    fixed_content = fixed_content.replace(old_prefix, new_prefix)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    print(f"✅ {file_path} corregido.")

# 1. Corregir Frontend (LCOV)
fix_file('finora_frontend/coverage/lcov.info', 'SF:finora_frontend/', 'SF:')

# 2. Corregir Backend (LCOV)
fix_file('finora_backend/coverage/lcov.info', 'SF:finora_backend/', 'SF:')

# 3. Corregir IA (XML) - Aquí el prefijo es filename="...
if os.path.exists('finora_ai/coverage.xml'):
    with open('finora_ai/coverage.xml', 'r', encoding='utf-8') as f:
        content = f.read()
    fixed_content = content.replace('filename="finora_ai/', 'filename="')
    with open('finora_ai/coverage.xml', 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    print("✅ finora_ai/coverage.xml corregido.")