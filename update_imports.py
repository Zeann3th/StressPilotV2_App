import os
import re

mappings = {
    # Package imports
    r"package:stress_pilot/features/projects/domain/project\.dart": "package:stress_pilot/core/domain/entities/project.dart",
    r"package:stress_pilot/features/projects/domain/flow\.dart": "package:stress_pilot/core/domain/entities/flow.dart",
    r"package:stress_pilot/features/projects/domain/canvas\.dart": "package:stress_pilot/core/domain/entities/canvas.dart",
    r"package:stress_pilot/features/endpoints/domain/endpoint\.dart": "package:stress_pilot/core/domain/entities/endpoint.dart",
    r"package:stress_pilot/core/models/paged_response\.dart": "package:stress_pilot/core/domain/entities/paged_response.dart",
    r"package:stress_pilot/core/models/capability\.dart": "package:stress_pilot/core/domain/entities/capability.dart",
    
    # Relative imports (matching with quotes to be safer)
    r"(['\"])(\.\./)+domain/project\.dart\1": r"\1package:stress_pilot/core/domain/entities/project.dart\1",
    r"(['\"])(\.\./)+domain/flow\.dart\1": r"\1package:stress_pilot/core/domain/entities/flow.dart\1",
    r"(['\"])(\.\./)+domain/canvas\.dart\1": r"\1package:stress_pilot/core/domain/entities/canvas.dart\1",
    r"(['\"])(\.\./)+domain/endpoint\.dart\1": r"\1package:stress_pilot/core/domain/entities/endpoint.dart\1",
    r"(['\"])(\.\./)+models/paged_response\.dart\1": r"\1package:stress_pilot/core/domain/entities/paged_response.dart\1",
    r"(['\"])(\.\./)+models/capability\.dart\1": r"\1package:stress_pilot/core/domain/entities/capability.dart\1",

    # Sometimes it might be just '../domain/endpoint.dart'
    # The (\.\./)+ covers one or more ../
    
    # Also handle some single dot or no dot if they exist (unlikely but safe)
    r"(['\"])\./domain/endpoint\.dart\1": r"\1package:stress_pilot/core/domain/entities/endpoint.dart\1",
    r"(['\"])domain/endpoint\.dart\1": r"\1package:stress_pilot/core/domain/entities/endpoint.dart\1",
    
    # Added single dot variants for others too
    r"(['\"])\./domain/project\.dart\1": r"\1package:stress_pilot/core/domain/entities/project.dart\1",
    r"(['\"])\./domain/flow\.dart\1": r"\1package:stress_pilot/core/domain/entities/flow.dart\1",
    r"(['\"])\./domain/canvas\.dart\1": r"\1package:stress_pilot/core/domain/entities/canvas.dart\1",
}

lib_dir = "/home/longlh20/Workspace/wasted/StressPilotV2_App/lib"

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            file_path = os.path.join(root, file)
            with open(file_path, 'r') as f:
                content = f.read()
            
            new_content = content
            for pattern, replacement in mappings.items():
                new_content = re.sub(pattern, replacement, new_content)
            
            if new_content != content:
                print(f"Updating {file_path}")
                with open(file_path, 'w') as f:
                    f.write(new_content)
