from setuptools import setup, find_packages
import re
from pathlib import Path

with open("requirements.txt") as f:
    install_requires = f.read().strip().split("\n")

# Get version from __version__ variable in qonto_connector/__init__.py
version_file = Path("qonto_connector/__init__.py")
version_match = re.search(r'^__version__\s*=\s*[\'"]([^\'"]*)[\'"]', version_file.read_text(), re.MULTILINE)
version = version_match.group(1) if version_match else "1.0.0"

setup(
    name="qonto_connector",
    version=version,
    description="Sync Qonto bank transactions into ERPNext",
    author="Itanéo",
    author_email="support@itaneo.com",
    packages=find_packages(),
    zip_safe=False,
    include_package_data=True,
    install_requires=install_requires,
    python_requires=">=3.10",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Framework :: Frappe",
        "Topic :: Office/Business :: Financial :: Accounting",
    ],
)

