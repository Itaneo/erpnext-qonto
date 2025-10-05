from setuptools import setup, find_packages

with open("requirements.txt") as f:
    install_requires = f.read().strip().split("\n")

# Get version from __version__ variable in qonto_connector/__init__.py
from qonto_connector import __version__ as version

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

