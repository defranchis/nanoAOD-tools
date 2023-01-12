# no shebang, must be sourced

# Check if in CMSSW
if [ -z "$CMSSW_BASE" ]; then
  echo "You must use this package inside a CMSSW environment"
  return 1
fi

## deduce source location from the script name
if [[ -z "${ZSH_NAME}" ]]; then
  thisscript="$(readlink -f ${BASH_SOURCE})"
else
  thisscript="$(readlink -f ${0})"
fi
pipinstall="$(dirname ${thisscript})/.python"

local pyvers=""
if [ ! "${PYTHON}" ]; then
  # check if this is a python2 or python3 release
  which python2 > /dev/null 2> /dev/null
  if [ $? -ne 0 ]; then
    PYTHON=python
    pyvers=py2
  else
    python2 -c 'import FWCore.ParameterSet as cms' > /dev/null 2> /dev/null
    if [ $? -ne 0 ]; then 
      PYTHON=python3
      pyvers=py3
    else
      PYTHON=python2
      pyvers=py2
    fi
  fi
else
  pyvers="py$(${PYTHON} -c 'import sys; print(sys.version_info[0])')"
fi

# Check if it is already installed
scram tool info "${pyvers}-correctionlib" > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
  echo "--> ${pyvers}-correctionlib already installed"
  return 0
fi

installpath="${CMSSW_BASE}/install/${pyvers}-correctionlib"
if [ -d "${installpath}" ]; then
  echo "--> Install path ${installpath} exists, please remove and try again if you want to reinstall"
  return 1
fi

pymajmin=$(${PYTHON} -c 'import sys; print(".".join(str(num) for num in sys.version_info[:2]))')

echo "--> Installing as ${pyvers}-correctionlib with python=${PYTHON} (${pymajmin}) into ${installpath}"

correctionlibversion=""
if [[ "${pyvers}" == "py2" ]]; then
  # checkout, build, and install in a temporary directory
  echo "--> Cloning correctionlib"
  local install_workdir=$(mktemp -d -p "${CMSSW_BASE}")
  pushd ${install_workdir} > /dev/null 2> /dev/null
  git clone --recursive git@github.com:cms-nanoAOD/correctionlib.git
  if [[ "${pyvers}" == "py2" ]]; then
      cd correctionlib/pybind11
      git checkout remotes/origin/v2.9
      cd -
      fi
  pushd correctionlib
  echo "--> Installing correctionlib"
  scram tool tag ${PYTHON} INCLUDE > /dev/null 2> /dev/null
  if [ $? -ne 0 ]; then # patch if python2 tool does not exist
    sed -i 's/tool tag \$(PYTHON)/tool tag python/' Makefile
  fi
  mkdir -p "${installpath}"
  make PYTHON="${PYTHON}" PREFIX="${installpath}"
  make install
  pypkgdir="${installpath}/lib/python${pymajmin}/site-packages/correctionlib"
  mkdir -p "${pypkgdir}/lib"
  echo "" > "${pypkgdir}/__init__.py"
  cp "_core.so" "${pypkgdir}"
  cp "lib/libcorrectionlib.so" "${pypkgdir}/lib"
  mkdir -p "${installpath}/include"
  cp "include/correctionlib_version.h" "${installpath}/include"
  correctionlibversion=$(grep -r "correctionlib_version" "${installpath}/include/correctionlib_version.h" | sed 's/.*v\([0-9\.]*\)\-.*/\1/')

  popd > /dev/null 2> /dev/null
  popd > /dev/null 2> /dev/null
  if [ -d "${install_workdir}" ]; then
    rm -rf "${install_workdir}"
  fi
else
  # First, download and install pip, if needed
  local bk_pythonpath="${PYTHONPATH}"
  local bk_path="${PATH}"
  local bk_tmpdir="${TMPDIR}"
  TMPDIR="${CMSSW_BASE}/tmp"
  ( ${PYTHON} -m pip --version && ${PYTHON} -m pip download -v correctionlib ) > /dev/null 2> /dev/null
  if [ $? -ne 0 ]; then
    echo "--> No working pip found, bootstrapping in ${pipinstall}"
    [ -d "${pipinstall}" ] || mkdir "${pipinstall}"
    if [ ! -f "${pipinstall}/bin/pip" ]; then
      wget -q -O "${pipinstall}/get-pip.py" "https://bootstrap.pypa.io/pip/${pymajmin}/get-pip.py"
      ${PYTHON} "${pipinstall}/get-pip.py" --prefix="${pipinstall}" --ignore-installed
    fi
    PYTHONPATH="${pipinstall}/lib/python${pymajmin}/site-packages:${PYTHONPATH}"
    PATH="${pipinstall}/bin:${PATH}"
    ${PYTHON} -m pip install --prefix="${pipinstall}" --ignore-installed setuptools_scm scikit-build 'cmake>=3.11'
  fi

  echo "--> Installing correctionlib"
  mkdir -p ${installpath}
  ${PYTHON} -m pip install --prefix="${installpath}" --no-binary=correctionlib --ignore-installed correctionlib
  correctionlibversion=$(${PYTHON} -m pip show correctionlib | grep Version | sed 's/Version: //')

  if [ -d "${pipinstall}" ]; then
    rm -rf "${pipinstall}"
  fi
  PYTHONPATH="${bk_pythonpath}"
  PATH="${bk_path}"
  TMPDIR="${bk_tmpdir}"
fi

pyversu=$(echo "${pyvers}" | tr 'a-z' 'A-Z')
# root_interface toolfile
toolfile="${installpath}/${pyvers}-correctionlib.xml"
# cat <<EOF
echo "${toolfile}"
cat << EOF_TOOLFILE >"${toolfile}"
<tool name="${pyvers}-correctionlib" version="${correctionlibversion}">
  <info url="https://github.com/cms-nanoAOD/correctionlib"/>
  <client>
    <environment name="${pyversu}_CORRECTIONLIB_BASE" default="${installpath}"/>
    <runtime name="LD_LIBRARY_PATH"     value="\$${pyversu}_CORRECTIONLIB_BASE/lib" type="path"/>
    <runtime name="PYTHONPATH"          value="\$${pyversu}_CORRECTIONLIB_BASE/lib/python${pymajmin}/site-packages" type="path"/>
EOF_TOOLFILE
if [[ "${pyvers}" == "py3" ]]; then
  cat <<EOF_TOOLFILE >>"${toolfile}"
    <runtime name="PATH"                value="\$${pyversu}_CORRECTIONLIB_BASE/bin" type="path"/>
EOF_TOOLFILE
fi
cat <<EOF_TOOLFILE >>"${toolfile}"
  </client>
</tool>
EOF_TOOLFILE

echo "--> Updating environment"
scram setup "${toolfile}"
cmsenv

echo "--> ${pyvers}-correctionlib is installed."
