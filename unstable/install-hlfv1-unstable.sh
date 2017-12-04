ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1-unstable.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1-unstable.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data-unstable"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:unstable
docker tag hyperledger/composer-playground:unstable hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� i%Z �=�r��r�Mr�A�IJ��e������6I HQ^9o-��HJ�d�x����4.�(E��	�*?���?�!ߑ�kz�U�(���U6��FOϥ{��{���5�ҬV�rH�m�nݶ<�G�@,&��h\�?DE���DQ�Ɋ =Ę!�ڿ<��6B�\����x���pFlG��u�"�p�C�3]#�:�!�	{�ӿL�&�?��E����Ro�:�5�mb�Z'v�W?��j۲]�'�P��	k�:�o�3�۱�&�����G$�.�Ml���C��}��-BWl]U�Y�N>��Ƚ�Ae<Wn������ ���W	������w	��V�̲��Ә�6����/J̿(F)*I1���]������G*��`��9�gk��O�VeUݦ��_&��և��A1�y+����*�~�	�;U��`X�JlX,-���	�Oe�N��QY��<`!��6L��&�%{��j���)�fSw�I���'�A�%!�������a�����w>|�X潴����Dt�0 Y��?2|,�p�!�S��}1��i}pHDQ��E��J���nP�E�6�Q��9ȵZmN��oS�31,��e#h�V�EL�N�EmϦ�:A�m[?�����GX�M�^w-����@�w��A]w�sP��-i�n�Y�D���UՊL<�r-�p��yx��5�=�a٬cCHO���FL�����4HH
~U�t;�]u����P�=.+��5���^�cP�2�Q��t���F5�m����u�3�(�5� (��- 9t
�;M�ĬS��M�I)�!N��7�4T���*1,��U��5����3�����������-�?�a�Yt`Vp��'A-��$Y�h\���(J�?���'�Zy���A�m`5u�@ج"���3�ٞi�f}p��C�k���r��'n,?��%��
}\��zK��=,��o �G�_P�&��5,�oC{�6�f���#���E`�FL�0h��o���(s5�F�íK7�^���5�f�bQ�F۽�����5<j,J� ���Qؘ��������ưN9b�'���vڗ���#���S�r�)�̤M�������TEB�c+�2�.���Х	裘�5�]Z�;�"�^�rQ ���.{��^��k�m�@�8�^)���;9� ��:]k �6�%�9����-N�b�M�`�	�c����U. �5�n�i�}��`��&�N�Bh��U&N/��S�|�b�8�r���`�9�ݠ�8X㪖I;�
������§��Ɣxt����?�6L���\�SS�_��Q�$9��X������|;)=8��3�́�L���5f[�Qcw���F�l� �Əew�t���ڄ+o�JJ�bn���+�&<&��]1pV�/���V(K�V]���U��\��a�X����_����A@��<�!�s���Eh�3��s���F���jb8�f�@�z+ˣU�,uT��[*���r.��=(����$�E=uLV�Y�օ��7D��5m���B(����
- �޾E���#Z�	z��=f[���:*�%���*���˟��*E"}��ɔ���B0���`�]�@��h~|Y 
?����_~�ٍ�'�g[�Hq��`��'��c�?QX������̫f�[�-g����D��JڰQ@]�l��΄����o܃�c��ې�y�D���}:���?*
��_\^����_��'�k�=1�-��0!��B!�5��6r �g0��^��0A����������������\��V�4�̿��1)�����b��w��Y.L;��xp�����R4[������[&8��"bۖ��m�t��h��ͪ�"gt�'.�u�t�ͳ	�S[�zl��~���(���D@���\�c���.�	�q��KZ��������_dcL/���Pi�V$
��J��H?���	��H��i���#��݂m��H��+�k�e@�4	��y�<�@@
��6��H��p"?5��4�J�H��C�cqh�!�X4��!�R��L��4p�̅�[����Y.�L����G��&����Jl�����T��Tk�Q��yA����.�,{tB���|�z�@���4�`ŷ	����BX����O�ֈy�)X6���ȑ�i�je������?˥�)������/K��[����t�D�a"}�i�0I�����t/߄�)�a7
���Kz`,��Y�<#��g�E��աP���"�i�P6�V.���e�QYBQW+��hpn�_` >"q(�n(ȵR�l���ϫS}+�w�M�РYU�Iz��+h@�C~Dq���τ�w�N�c������k:�'��Y �J�f|FF	�nP$_4��:c�pC��'��I0]�v��N��������͢�(���$��U�I�{~��h2�Ha��� �~�?���v[[�D�Eݰw=.(�������i���Հ�gd���+�-�.��9n�B�j�*�E��f�<�~��M>z�#w������9���(���X��N�f�W`��v.M�w�C��^���<j���]q0g�W���̇����5/	6�n۵�#R��:@��f)���!�x�Tخ��Z%0ip$@ "�(c\H<V�	Z|-*�����ɕ5-!KQ��ZZT4,��q�"�1N`YV��&���s����&]�7!�he�MZ,�?Ph�q"�
�����b���N�\��*1���4�QT_�P{���7��B��t�@G��,�x�h�=�m���Ă�CLͱv��
S^�8�[,a�S�Lx�	�A&���Q�-�.1��I���	����w��fI
���)r���bqY�Q	�?I���s����o>�̶l���z�Ǆ��]1��3���̄�?*8_�Z�4��󒂦���1����=������Y��a��O9���<}��[��]pj��F����eh�=�F��\�	�R����֞� (4x�C��*��Nn�k(����x�?�r�m�npɾ��5���1̯�ZF���˭�|�j���ч����/��8X��_��~���� ��o$5���;��=�m�5�c�㒲���|����������6����A�Kc���(���������������������_�;�����D+�&�Rb����('p�R���D"V�$h�Y$rLNTQY�rBI$�J|M�*k�����s��'��.�3��j�mГc0D����?���ң�9.e��e���Z�����z;ؠ����n�Oߍ���~�n@��߱c g韖��?[�z�t��8yd��j;K������_0�S$4�t'(���|ލ�/=�>|��3��ڸs�_��G����?]�KS���Ͽ(�%Q�b���	�����e�c���SWC�BY���mˠo�����<����c��_<��z{�D`}����%O�%�Y�1���ʬ�hB�S�䇂�@<D!����i䲹�Zΰ�wf>�Km��R�����\R��j��5Ϻ�Hr�k���V�i�wR��ܶu��82���.2;@Amn��A&�ȧ������T9�,4*�F�}���y�T=��r�����;Ske�cɸ8���7���*g6ݓ��w�Ѩ�I:'%�"	�[i�8�rF*4ޙ;������Vȗ�N�4'��9a����h�)+ze�̣�d%��tR�������L����E������K%���R��G'gZKi�3G�����|�y e�\�{|���7���E��O
C�t����.>RT3_R��u��sc�U8���'0���f��q���j=��J�;�-Uȩ�Mom�<�/n6�K����s/�я��N7��q8*�_'�̝��a�(Ԏ񶺝�Ւ�+��I���I�J񜓯�c'r��Y�l���ɝ�*�\ ��t'��t��o��j���V1�Tkk�TU�)������7�m5�l�'؋'s��;�.�4;ۭ��H@���B*���keV��W�~�`S�PW�Tn?%;���wf*S�X)y_$��D�a�<��s
)�G���Y����%e;f�
��U+ke�8���q���|s���Â�Mɉ�Y�pPT7ޙl�g
�	b�_]]�#�ȫˬ��f�t̐�g{�ا �wC��� �L��<?#����e���M����g�����}�����4�S�����QP ���s�!;)H�@ۙcV����6�`OVoۣ��BSj�.���Nr��#	�Y�=�Nv�C�$�!��#�83�i�]��M�k�ɕRբ}�r�
�v��y�ũ���C��2�gR�ɇ̓�~Q�*Y�(�[Ҧ^O5����ʻ���F�^w'�UH�$�+�z��w���ң�����_���Sژ"� ���P�������'q��Iܬ^7�����#q��Hܬ7�����q��Gܬ�7�s�M�]�o(������������_���*_��x�u��$�o��7���;�԰��mv2����K��}/��k������ɦp9�:~T�"�H^��x�}�Y�ٓl��!�W<y�f���e��a[���i^���2ս����s!��6��N����an��/=j��3��&M����+�S�?�����)�_��<�	JY�����s�<�e��H5T�e*�.�a�	Ͳ�K�	���z�cy5���h��7����������v��Q�IM7u�1k�hV��*ja��U� k�V����>Y��(�����v��gZ@(m��n����ZV~�mS�|�M46�%B�5-:��B��RP��aw܆~_ꁸa�~�|�r\��Ń�s����;�b��� K���C�ߺ����.�������^�F����,�=
��^u��%b��:���|7�^B43�^g@]˳z�F��l]��b�[Q�����M�2e���2���.y�K�O!�úM_��M�mwi���rm�8@;{���K�vؽ}@u;��¨��dL�zZ$=܋UTn0��NQ�������������e�k��.S�Xe�����G��G���֫�~��(�gS�_�K{��ܟ}���Ȉ�
��e����c�Yb\ǲ��i����<�?<��T����;q>�<i��I���u*��(ٱ��ĩ؉�H=iZ����쐘[�fB��`�;`�^�R�W�UuKS~z����s�w�=��'O�_.&?y�{!/6��������$c
:�\����>����s ������"�L5�n�C�vs�{�	���;)��)���p��q��L��T87��O�T���Q�\�-#7��lm�,M�I_�s�)���P�Lg�m���4��9��JХIi�WD,x��\1@�xR@��R�a��T����ʮ[*O֜�쇄�vms
��bE�����x�B$	�P��?u]�A�(��HQ��G��c��̀�����&{2��,�|���Ǐ�H�l�x#r;�2C800��pjO� ��5��"�+�~�Vqٴ�<�����`풦MT�v{������� %0�]X���P㻦a�Ƚ�a����pw��=o%�����T��"�ݪș�'�+�����C��#���b��|o�5����]���4�Q�1D<tjzC-B�ݘ�K�׿���# ��G(��u\��'�����$���q+�� ��H���3�������'����������?��������|��>#���������൝���"�C�kȝ��|�D2��+��q%�L�D"O�d%Nd�$���D"C%��R��B�$Փ�R��/)GD���7���7O���~�ǟ��ܩ|N�����#þ��^,�Ooc��nQX��y;�ݷ�]����[���]�����}�kB�����/�G��>��}s��_C4t�1x��C����J?�n��F1SP)��0,}�h�ipR��j,}�,��1vݳc���w�����g�\W`L�|y.�m��b�3�jΉ��K�N�s�F	'	�-ܴZ��	a�]�E�p�-�ơ(��s��sΘm����0���F_�����8�AZ}T����K�gB}���ရ3���yix�h�G�7�m2cu��k(�q��I�Am�x��jlP#�d�aӃ���/�f��N��R��:�툧��u@,�r�o�c�2T��U��V��7���2�+�ĩ3S��fd��R�'�b�Y�U�Z!��`��P���H��G��y�����:(��fn:4<[_�ct�^Kp�V��m��,N+�67�S�t�u���7�Y�?2��h��O��l��Ӽ�]LN�F��f��	66Ϥj�����ɞ6Nd-�˶������GF�I%�Y�Ѵ�t~��gc9)V��`r��U��j=!}h5�����ѥ�tgTrgT�gT¼���(�d�5�I%��x)�4X(v���͎D��aN�D�\�Čzv�8+v�/E�0p.���|�A��<���B�}mуA�s=ѓv
��nމɅ�̗?G�޲���b�|�8�����!�q[OuZb�{�0f9�̴
�@��"��"��b1��'�����C�T�&i�S�Q������ϳ��TǤ{{Y:��IX�ɕgˣ
i�BE�O��M)|҉�k�ι�Df�L���\.�T�a��(�b1M�ɍ�--�/��]L� ��G�=c�ra@�\�rp�'��feҭbJ��J�A�����!w�v�����#���r��N�5������o�z�_P ���{���᫕n{�󟗅�|�)�4��"�a䍝�Ev��?x'��z�5Q�y/v5�w$���j��KA�+��w`kQR�{�D��X�+��o<���>�����G��~�&�ť����L�V2��ӳ�h�L�i-�\�~�Tz�32__��ϱt×�Yr��N�e,,�P���®�5@x������\�˺j�y�˱79��4}\��7��`PEi���h]OX��Jp�@{�Z\���$r��4�M��qU͝԰L��h��̐(W�1^n��a�����$��j��{�I�V��ZsEM���C�H;ؑHW\.�F2�e��s$L��hm~�Y����̴�V��L��dn9�:��t�����R��7O�/�v�a�[4�,�lMPj��2�����T��2!����!գTbpT���h��NJ�&�c�jl������O�^g6*���b"����,�Tp�>��;�M*�r�(���(�7�5aZ*q�R�Ҧ�����p��ޗ��M9��}����|��bG�����(�p�2;X���n�9�'\�'w���;�t���5����2����D8^B.���b[z+W�g�dTKU����i����F��Z.E�-����en�&0�^R�Sv2X\���*=J�ٓA�S����i�,p������2�*�Y����XN�l��MZk�ej�j��r��L3zӽT�z �tBW�H�y�j�|Q8#� `���iA�t��U5�9T���@l*c��H͊���P:�\a^���`4VL��|o�-�<��{��±�F�O�1"F��e�����g҉��R�(�P�,V�D(φ���HOM"Ô���h%��ޮ 1�<�	�y���[0B�A����/L��|�0��r�&u����y/(��(^kv��=+i4�V��֐�L�|l0��k��Y���5�[�cB2�L�]�R�]"�I��4����LOg:�^�'P�\W�`�D�"PR�R[<��1���ґT�n���V�E5j�D%�]v���P78o P�_�i��E�&ϧ���He�Uz6�I����+LFoF%�i�۱�4��I���2��l�X��N��iTX��]DL�^_�E�t�!����a�-(Dz����W*�:�a�=]��Z�DwO�";~����"��UG��c5r/���ef�e�F�����T#oE^���=}��x��S<��-��Gt�Eތ���B�<�|�}��g���+����tEoB�z%
���^A���H����C��c����e�V�%�@qN'h�v�<_���=orhE����Z*� {׳}
�#���E��Q��^r��=��\���������X2~��O"~��V����������q�s=��z��z��"��k�n��Sa�*���w
���9<H�<�0��,|,M��j#w����vM�&x��}���zd�c�g؄(��y���?��}��U|���}���ZUXk��]����8~���	ކ�Y׋�=l=��Z=C� �+b��4bK�A���-Cz{���)�n�&A���p\[��E�!d��a�a��=�X��ѵ�6E����
u5@��	�]!�o*z��1̾] �3���o�#>E!�����]:�q�ƭ�95|��;�<x:�~eꎗ<�}��� ���Րm�	j��,�\�x���$��=�	7�0<ޘ�IC5z��C��o]��HCF�3�0��X��9�߃2k���q!h<Y�Ԉ��Q��I+��� �~��ķmE�ɍ�9���5/��T��;0�>�~�Z���_'� ��B��$�)P����It��nX�裮>��}�n�'0\[M�F|%��kO$:f�.�+�=���CXWw�i��x�`�þ~�6�ߺo��\���D��W����iY�׿��c�`:��?`ТӳME��pj͑gѺ��ބ{o82x�C�%�А8Թ�͵ �G���1l�8UZRB��7'q���Wʫk@����]D@��Q�ɣ|��#Kr��l}����dMTY�����6��0�@�{��K���k��7Z���J%���2�m�g�n��1@I�x�K�"��݁�H�٩W�[���,�W��?o��7�b��6��^i�<�ɰ����~�Ad@E��˰,����Ik:�H�z�Ȟ���a|=MF��4D���#kE��[6l3;���p:�V ;V'C�h?j=bn�܃�!�µ�2�)���Zfa�Av��O?[�s�'���[�Y ���D��-e��U��X�W�٫8��&ܺ*Ҿ�Ŗ�捃/�}8�'�o�:�@p�lܯ5��Ո,���	�[��l��j<�ή�"H���H'�����9��4��]Gyp�}�I ;D�^(+�\�}����Xs#�^�M��6�4A���?b?ː+N���F~Mx�m�.�T���C�M��[��[����3�T�1'�o�k�/�9n����Q ��툃�
�`ۊ�&;��+N�m��<����g��q��*E�7�P�ԝ��[y�������Q@�Zɖ�K.�D����f-xV��s4S��Y�FFzU�nt+8'�lp�C���i bKc��.*�r|�
��V��x�����l�H$�H�8��II��T�T%*�Ʃ^2��v���z�$�r�ϐ�ܓ{���H�U�LJ0
.0(�B��wa�-7�J�b�����~��W�������z�^l��`�\�u�l ��$')I��X"K)�B�j��2�$%�������i5.�
!$��H�3j"�RRR���e7��>�;�C�o=z�Pףg�ܕ��W�7^x�c���6,����ߒ���J\�l+u����se�N��K�|�;�J�U�j�g�"W�Y��5�cH�����m���1��$�v��w�Ϲ�vA��tIhTy�qh{��0��&�0�� �}�{�";V��L��Q̈́�jQkҍj�ݟ�����:��*�:\2���-����Y4��k-�3n��a�[���Z7GԾ}�d;�_��r>��BW��l��A$����q������g4_�V�UN�&X�i�׳
�\��V���x:����h޳�ΤIt2y��#+���$��`䅻G�>��3�hki�ml%{ �*1[)���q�[��� z��'�����J�H�ݐ<�	��Ы�X8K3����&�c�lC����'K�4C7��Ys�������f��2^��_� uaqEާ2��%��oK Ga�Co�Н��=ɰ�sH�X�$o�<��$�_ǩ��+H>�7ݎl�)c��Y/�c����W���Ցb��n��<����ǎ����w1��Alr�����B�-�e����b3p*,�p����ٖ�����jq��"���_�L��$���x}������4��������'P���������������T�n�o��J�������cw��o�y���+]'l��s�m��5�2~��o��*���m�
��;���m��y����=?��m����Q��w��������͝�;4/�͗M���|%�?jK��;���ٻ��Dѵ{ϯ��]�e.�Z�IEE������	���T��K��JU��<�*++�j��w�g�o%�J���^]`�,1l�]����������C�Eو�	�!<�dC«(p��e����h��'h�N��0�W	���_����?Qk�l�d������GZ+ڷ{��cJ�>��<G��Iv_n;m������e&�{�����k�Ǘ�:e�d��#w��[���JTf�<ē�a������M��b�^K���t�x4����}�x����u������?�A��
4��q�A�� ��U�������?=����������0��U�f��Mj��|j �����s_��_	��O���A �U������������������hu����i��J���OC��
�U�pU'\�����)4B�a�?a��4@��.��� ��s�F�?u7��_���Z���)�~�'��W����q������O��,k��u��T���~���e��ׄ�e�Ӻ�~"?��y����w�~�V?���~E��fV	�����|Y�DV��sAbW����j�"l��~��3١����w�����Pli���a�w�}c:�V�(;�db��v�6}�Ajι��������g���{&����G�߻����b����Pf�e0߮��nO��ާx9,�k{�sW��9s�*[����xG�Y�K�RcQ��־M��ij����nY���hkx�WUم����N2�������_���D�P��n�����mh�CJT�h�������ߕ � �	� ��^��@����@�_��0�_��n����l���)��*�(��C`�?M��0�_^����������3n��y�G4���:�vj����N����Ͼ���/��䢉o�����Q��1-y��g�[��h,��x���~�QLw�k��O+Ύ+6��*ȁ"(q��%'��}oJG�p.�����uMΞl=�W_�_<�z�y'@�x�P�-�R�BI����>�[�����e��d��JQ	��N���Ʒ�����b�͙�����*h5��Zg�.��M
�>1��&-�@6Y�p�š�t�M6���������=��*� ��
/Y�B��5 ����M����S���+A��?�<��#
|����<��P��I���g}��	�f|��|��i�"8�CC��q4��������2�?+��<'B:jw�:�diƞ%w�mx�E��޲��������,��9^�<yq�P'��E�1q�E拁sX��#��o��fK�^v`�8��D���]�4�v혊��q;>+nЃ����	�?�և���|]�Zф��_}h���Omh �?��\m`�o�'D��_}�����uT��i;���D��8��G۫�A��K�Y��f�������1���/��vz��e{�D����xvHt��8#�S*��uYB/:�,s�)�"�GSC�Q�l[�C��{+�q��P��	8�}���;���4a�����������@��[�X���N��*��sʫ�������̻"��͌�%LN���.�?X֒�_��K�g;ΐ��Z�� ��7� �[=����T������*U�v	��w ��)Jɱ���� O	�L��
]9��:mA�ʠ�]��4��b}<0ꌗ�C�}ד����z3KNϷ�e��;�}7����[����ow vG(4��B,w���D��.�.�k��(Ի�� y,V�~(�$VXV�	s�餭f�?o �BZbg+���R<~Ը�����i��5�y��������/}�5��=!I摤�HJG����e��O�eȵC3Z���u�I�9��ڔ-Ⳡc��ee��}�7{Ѡ	�#�?�_����wa£�������C����a�������������?d�5U���������?����������?a��_*��z4�z���,�n��!�.�.M�\Ƞ,͆���� \��I&�\�a������h���O%�����;�JegS��±p�J<|2�ų��B�OȒ�525�����9���.�G�,ɥ�n����=��*��vC�]�)�!��c��^&4���Zp�{�m��`z9��X�!Jl:0��V4������@��|<��"�~���C��=����h��w������l�xo"�����������_E����ۗ��vpCP��h�;�A��
���~������o�8�N��%h�K:c�T^����o��e�[�ݗ�o����~߾�����������wQL��8w���S-8ȫ���#���Φ�M����g�\�.����tl���v��N��؎�ʫ70����qv���&�dZ0�)_�q�.-Kh<�En�\�9���l{��qnasp�##(�ƃU�n�����;P�Ck	ާz��鱗c^�mQ1D2S�x�Y�dݒ��\{�uZ��P����ń;�A;Vb�R�t��/A�I�++��1G�M���E��Hr�)��1������wU{p�oM�F����M��ϭ����8F@�kM���a�ih��4�M@�_%��o����o����?迏��:�@#��s�&�?���C����%T��F������
@�/��B�/��������������/��u�����O���M�E��?�_����c�p,���������5�?�C������{����4��!�F �����ԃ�_`��4��!�jT��?��@A�C%��������O�������GEh���͐��s�F�?u7��_���R����?���P	 �� ������&��5��������׆f�?�CT�F���$�?T�������z��������/Kb����?��k�?6���p�{%h����h������ ��0����j�Sh����?�_h��[��,O!�� ��s�&�?��g��M���AڋP�a	��X.�|�c}�ĉ��(�\�'H�w1�q9c\�sI�b��}�'��E���1��5��?+���?U����n��8�r�B-�[m�0bU��@PӤ�%+�F�!?AMl���z}Zw��/Ǫ�ŏ�1��<?>��̰��N�We��V9!7�:mya����}1�ԅ�Cʞ��n����Nӣ5�C����d/�g��&�E��_��݋��o�p�C�g}��������M8���ՇF�?��Ԇ��������f|B4����Շ_��F>�Q�V>��Nk�5�B���{�/;��_���u��?+\���\�e��,�pX(A�>JF4[��~ܹJ��sGٷ��Q��n����]~?�k�hH�vX�����v9ZȔ��h��w�;�+B����?�����M������ �_���_������@ցF�����?迏�k�o�����S�	�tB�S�@o͙�-O��o��:ٯ����&�$��.��V�u �?b7����[�i��i���w^��0	$o?M�^�cS=a�A<��qFNU�Kzɗe��#"��K2��Y�����M�^�M�/��-���щ�����&\?!�;����_����w�^;�G��=M�c�2?�C���
�"�lH��L'm5�_�yM6D�ǜ={�I��c�l�	(��>M��ypv"�x�Z���Q�DPƳ�����M,�W�p<�ƻތj��=�jG�������?���!���o���$N���� P����[>����[��7�?F@��4��a��O��������#^�E�����Dq8�+A�G���/	�_����\O��h�����`����W��*�Z�O�D�._�?4��1v�Y�5���%��\�I�:��#��K����,M��s�M����^�y�Z�x*�!����|��������KW����V��U.o�%ȷ�%S�����RiU��UWM��@����=�Uq���9������;�]t��Ō��8{rS�q�lY;�]�9�۔�0�^�v:Yt�u�O	�C������-Z����T}s�/�����B<�o_�?z)�!O?l]�e�ښ�����HQ`����-��o���q�-��j����/��Kj=�*s��xI��D���d,&��ᝏL��c�w�B�q*�R�+���mW(��=�����%��m�\_,��9��C�������������oE�F�1�z4F���C��"����I��"��Q��"�!	.r	ƣ}�GC����� 6�?
M�����W����W��Kt�='?*��[{(";�a>�F{wy�g�QJ�G����˕o�
��rS+0��V|���������1P��M�C��?��U�
�����`T��_�����4�J�Z�oP�����������%�H�^t��� ����Um��/:_��z���
l��j�?�������J�j3M�_j×��K�y[�� ���B�uz̑�~Kڍ���@8zDNOj�m0}�Ao�k%t�$�§yq�~����!�����l��ǉ��One?�u������zr�I�'�u[��0��M���/Ҽc��)��W%�"��~|2/�Ѭ�a���l&j�3�\͆W����6���.|D��V�����+�r�ض�ï�u�n��-@�s�� !	��d�b� ������_���ݒ�m����Z�i�>�T�9�`^+��i��T�����ڪ�i�L+bm�I�[�1f���	I�ĥ�?0�7D`�)�VHE��Y�hY�G�lQ��j�LI����أ ]0��!8~�����{AD�������D����+��S��Z��J�f�䄑:��6d�s�|�P���y�d��>/[BՂ|�l��O�K��0��W��1����I�8}����@��h�R�WxL$ �C����a���1��@��� *�������g2�������a��v��֨��ޢU[U�B������>���<{��^�O���},���i����n��( �D9�w�L-?�֧¶��m�s�&~�����B�4r�|���i�
�/]9eG�۫	��L�W���Rx!��<�ʙ�t�{���׺4oV�Ĩ�uW��8߲��Z��S����9�`W��I�kWU��N�Ҳ%6Y+k��Yz\g��hY���B
/����a�G��#_c٠r��r|+mV,65��[MR���Z�k�30��k��\o)�u�X������-�`kҪ��M�8���`��M��a�e��hb����Pڴ�]�d�|��KEmƗLQ`XM���/tr>+c8Ft�eg˻�9}�7#	����7��	����������[�%����O�!J��A��D����?�G8�����?��O8���K��}8�H$�����_���Ǉ��&�K�����?��0������o0�;�/a������C������4H�3g��a�ψ��M��!!���?~��0���F���?����! �C����	�l�\�)"���0/D����?v�'/���C��	��"&D��_���?��	`����x�H���.�����H���A!����[�%��3g��������!�!��Y������ �?��0����/j��B����n�������!!��BĄD��g�����#�� �?��0�C����?��H���LN������/�O^�� �E�d�?����������������׋D�?���?1!N�7S��o�*t����_��K�g�3�����
Mช�YfBIJ�$z"k9B%M�h�,��LV��V4M�I`E�Xc24FS���t�{$��3�����G�{��-��[�V����/�X]`k\��m��N�́��<��W�)�h�t��-Tz��`yy��G�[���p*����U��F�7�l8\ݭYZ�N��"Rܲ���c]�4H�?C�:)��:M��2יSrm�j���q�+����r��gym+V���;e���;{��+<aH����?�C\�ߟ�Q�$ 	���!	���ć8��p���]�I���Ň���8I��U��$�!�!SI9EuA]��Ϭ��t��:'��"�g�I�ѝ-dŵ�ز�X�����+��_�3��z�bꥌ�^V�ޤ,qj�����rZX҄�]=]�=i�j���{*�a�3��7&�i��Fq��J�!�`�Wl��_0����/���_L�?PƈD�?�>�����������q��u�w���R[K�͢�u����ѳ뿻[�sn\�y�=Ё��agr����D����A��0���ەQ��I�O�5L1Y��RC-����id����d�0\4+��&���4q2RKZ�^e�6)�2��ܲƒuv����b���^�uz��5�.�����a
���Z�R����^vAb D��N�	�<k�O�|�%rO�@�XS`qv���K���VQ)��Z���F�5��b��Au�M6��/��X�nS��,x.�evj��n�I����t�P���(m$�]��5�}$A����^����=�(��c�؅���/8����g.�1���@d�ܸ��ڄ�����O`g��b(��Q V���⮀W����c��B��������E�㮋�����c����8�7$��a���i�G���?� ���?���������_��"A��� +�����_"�����p��X���>���a�G$x4�c�Hw���]7���5���.0�!=є���m��Z������~����������Őo��C?�'��k\���8����7�����2��)��^(1+��˩��T�����`]��x���DyTJ��96+�B��BV�)�fL�^V솋BY7E���~����=��"�~%Y�-L�M�&�ӊ)��b_*�KV�7���б�+�f;��\��e͡��5�E��Ţ�c]uȐ�a��:F�閷����Rkrc�`^+��i��T�����ڪ�i�L+bm�I�[�1f��� ���ǆ��߽E�㮋����n�������!I��߄� �"����_8��0������_���$��	�뿻E�㮊W	���n����0��1!A�����H����ǆ���|>��/�cy9�+%�g��U���u�[����������AP�O����hϕE{
S�� ���m@v�-���%�VE"�JV�KJ�f�ry�v��(���b*3����_�Y<��G^ۨe�F�P
�R�K��Ls"V�ӟ�@� �o�@� ���hl�fE}P�����-\d�y:1�"m��ɒ�{D�(x��U_c9�ŋ���b�W.�*nR�Z�S%m��4���!ު�a}�n�W#������	b�����]�����/	���/��@����2G2��a4��)���I�	��d��q����T
W4Lb0M�Ufh5�e�	M�^���������'���s��.3f:&ie��h�0;�_�v]�.��~����FY�ԑ�K���ܦ���HW�zJq\Ip�����J���HqF����I��ד2�˚Dj��5˾�)
�ɠ�CA�\��M[����T$������!V�.w�r$��C�/>$������;�n`�U�*����_|xN����cZ���2��`H>=#����[�z�/ԉ�(�p�鷖'����[j��.	�q�d����y��je@!���}j�e��\"��ɶn�V���U�Q��b�v�9�=g��6�X$���"��l�Ő��G����"��cD"����� �`�����_���8���I����/&<������;�W5�X릖&R�t����u6��o���1 ϩ��. 9-p? 5ӽ�4h)I�o2N��^����$Y�����@>�Y:�L�Y���tg�v�E�QN�zڎ�����r	ώS�e��Oyn��T�!���$6(��:��?�X	F��� ��l�W���0^ �0��<�?��*N6[���\�
"/�7XC�3�7di���sX��'�9܅-v�G3�sŤ>�#�t�oz���9�9Y�Iv�\R�NQ�~qg֔.=v;��ۺ���@��j!yJ��<%�Wz��B�O��R�IoD���(�����a�-������<�f?��	���'H�d �G��9�U������Ѹ�����l�`ԍc�>Z`����ŏM�[��9�#���MXܵ�ښ9WQ���4R�.�zm�|g�ss[��7��׵~�#�;��Dސ,K����]������~���G�Ţ�m1��vIf}a<�����/���xƗ]��?�&��?c�&�Р���?�WZ6��,y���
�Gm�L��Q�um���㚖�J�y�b�5�nO��ku�ɫ���ݠ����U�͗>�{eI@'��%]IF}CE��몠��那mw������7oQe�������������N���_����B�]�����JEWz�� ����U��ZX(�ϫ;���17���X�P��A�'��B�v���Qݹ:�U=�Է�}C���"��m�P���ܕe���������O�����~ʽ�.��~�5���~��\r�+Y����� �b��?.�'��U���^pw.=��#;�܃�����؍���}~���xT9qm�\��Fa��rpX�i�W��]�OF���7[�M�s�j��C�|����m�cS�k�&ߨ��ޞ��D���B~<,S��J�WO��ix����G?Z�������y�������� �g�)��N$�!`���(���㮝R�Wh���?C0���q��I2�����?|������+o��e���/����|�� n/�U��S���]��~��܇�.���^�桙�U�Gw�^����E��� {����IW=p��owa�o�~�[����waA#{�������e�2W%��V���?|ҹ-M�������8�pl���������
�K�������%���@c�{Aqˡ��7�[��gߗv�>i��-���o�k�Uצ<v�"}�Y�j���ģ���k�+Ř�O��C��O���;�md���@>�<��Tf���������d������"��2}�$����þo��괱��>�o�����^�a{��`��������7~�!����I��^_�g�����{8N��C��������w�8�bj[�<hA -`j�	���A�֡x�6a���O.0���|����W�à�L� \��W�'��u�#"HSr=�#����ޡn#���}�#z��(���3����Eopp7��@��s�]��CI�6�z���wW����>���k��>�g��8���K�_�N��]��X��b��hw\P�$�s,T�>���(���C�o�AL<00��&���*,�*|~�>��]��4D3_�C1|I�h�P�([��A���
^�n�А2Ï�5v�S��-ݝC��䚶�I�� ����O���z]�A�����/�~�>�?ڟ���7�>�%�R3!���O�dY�����N��|�\�����q$��;��I��fw�ٯ4$T�����t�U�*�Mm�.��v������U�*�e�]n�?�^)	� 
h/(7ܐ�Wȁ����E� q��^}��v�L�r��������������:�Gm�[C�h������Ei6�⏆���R��.�b?���h���t�l΃S�b73�i*۶<�V��P%�sAE�Q吤��`�qpچA�D��)�䯑�Qo��Z���t,�>�y|�|��4�C;q��S�n����n�?!}��#!mk8Pv�~ȯ���L�~�)A�a^'*}4��`|-R�S[���NI�+]i�Ɋ�����:��bƷ�mn��p��g�}��.�۔���;�����G��`g�R�c�����&@� �
*?�b��P[�2_�2Bc�btj������E1��h!��(�p0n�#ZSaa%��A-H�\X�
tF�
��H�
�rDf6thu:�!�^��'� r�](*d�����&=c�1fr$&�i$�W�mޟʍe��׮�z��k�u�/�s�r�R~�E�Da;���bX�^K��}����`����E��il3�:���.zYbB�6\���Q��Ϟ�_4�
��jǞ:%�90䚬hNJԷ��uOŗ���@sD64��T��m������#�k��]p�����<�ү�{�.�4��n�z-n��O�\z����z��,�-��i��s7��/�����_�A�����V{Տ�c���\�I������?�Z��K�˩���b��,T7��"�����g�BS�Ⱥ!7�'c�׮)w|_t'o�3��˿�
�^�%�?� �P!������������&�:.��f�����o�_���68�ٸ�yg����~��Ɖݝ�>ւ���0t$�T(�b"r��d�p$�5��C��P�1�F$�(2a#�
�t#̲���?�NL������``�
� ! �^A�G�K��3�\����6�& ��o/}�/n?��Zȓ[���|�^~ZĻ��/�}��l�4_���:��w��B��x	�4EMVWh���#��˵���y�y
�?u'�:.�.Ĝ�~#�/�y�����/�Ĩ߆����^�YdQ�|����2+?���ַ�mQ�k(�W3�%�����mz'����#���K��{����&�ZS��#�X�\�d%��*��鄳�O�MU=�&-�g���-��Tpeo�Y���]�����\'�K;�8�y׍J����g��ix{�"\����#M�w��a���Z����xl�)����8�����凉��_�-�.�mQ�ʼ-j�sO�\7�^[��>Zd�2������Ij}��F�[�1�w�R]]a!��n� ��9:��vz<�|�C��n��N�T�j~*�q�:/.kp���ЖF���md*�Iy8�g�B��5���X��P�>)G�S����Py{�đ䃢v4և��!Ync�G/�S��!i�}w_œ��Tt�zf�捥0��s�`g9�C������ꪆT�W���Ʋ��pyl�ڳ����2b�>�O>�q;���|�9��c߹�L�:c���5a�pl'�1�l�m��g�h%yFIP��:�C���f�v��������o�&L�{��3�SN�/uey�!-B��ʭ���ɵ���Q@�J&
�,�����Yۤ�<<#}~}�ŕ���/е3�6�X�V�D�g5G��]s�:�upȎ���c��O�d`純�م��f�3|���\�xb�?ڦ\���ch�f�D��/��bKH>��>|���7ꐩ���vL>(����nz�?����FñbG�`Qy���;+"�5�d{����
��Gc4 P�(�؂Ru��<��0Gm�<G�[v3�]n��Z�m����b��\A�-�pT/��q�ÍWL��Q��uM�S^�q�=m�N��n4�$�%,Dj�������𣈦��cH����Sٹ�%g�+�l+)+
��"�5�UK�!b<�EpM-��=1A,��a�o��yu�����`����������6�`�s�'��_��ҟ0�+�o���E�o�볟��g���'�B�>���(0�޸u��杍���Wѵ|�IW?���ᠪ��	�!.�QL Ȅj��h�a%B�V)�f�r8B�A����&���_��罯}�g�O���r<�}����������
��6xu��f�6�ݷ�m����÷���￵����R)O��=��{�?�_v�Ԉ���e��B'㵞�T���v8\��HJc�Ne�� (�D�R����������\(K�"��J{:a���D鱃ZY�Jт�t,e+tb,
��Uَ|��4�B]�*v�Th�}�ĞĒT���bI��$XOxy8$ �$�7��	,�&��ԝ&��q�_9>����c鴞p��&��L�Mq�h<��Z[�|/=����Q۟�[B�M�G���G�GٶX���F|"�.T���n��DvR���-Y�p��m�٦�����dO��)�G�kIM����,�ĕ)�p����]b�Uh%�q��V�	�2$�@=�N�&�M
�9����f{pĜ�{ʱٰ�7*�Q�&-i�#a��o�
7�j���*��|/3n��䁡TXN�TK�Q�O���d��ʹ�Qw�'�� 
M)�o�����~�BiJ"iR�@Ų�\?�5S����<��5
�@Ŕ��K��TLHFf������z���M#�:���Z�i��d��2�vDZ*��\Y��(���n�v���V1 W3,)���B?�V!ˎ�*˯��h���D>�����*�=.��}33	e��^�Î�xT��t4��t��!�Xi��=~/!�%]g�P=TL��l)$Z��/ruF�%[ӽN��H<��Cs�j�y��E�c|��%*��i�+��x1���q(*F#`X�t�{��A��)����'�t�M1�<�x��F��xI���B���
�	��F��1aya��_�
�EV+����~dS�-�Ub�8��M�T3a
Y�R$4.��})���,�DB5[)���E_��R<M�AY.�
J)��Ζgv��A�*F��9�e���Q��g������KUa��y�0_��Ԧ,C�]��1�����.����p��A�9�s�~������(�٪S��Hի�ҙ��hF�)��6Tڢ��4���^9&Q��zqj��������Ԕ�l���� ��\����&�܊�& �HE�N�9�2�TN�;�)��T��ۅ�S�ߞ���	�Q`,$"�F���NsV��&��j+����(��nL�2!~7��.�	��޾�U��P�5Ќ��n��M�\O8Gʼ[�w�����w������K����[���2'����_.�wB�1xˉ.�H;pq�7]����6^&6ܶo��w���y��)�/|���� 6`[^!n/y8+����$�{���&X:�"~���;���?�G��=�{��g������/�\�ң�hu�B�Nm*�l�\~�@��4QpP:�,E�<�|��\�Y@D��� �?��W�\ y�C��/�Q)U�ΩD*4�b\z+>�k�ND�<S�쩑���b����{�|]�k+�54�$���:�[�fu~�K�[�8H�#�x� �.~<X /7�yO�����W�ɭ��V(4����@ǳx-Q2�U^�u��X ��ڬ�?H6�r����S��vb�9�A�l�_�z��T�	iI��1X�x��}���V}��T�N��+�d��Ùjw��|�q��Đ����B-��J� �3!��Y�q�8?e����W������I91��]9�˶]�<��2���Y�#̲��,k�0M���^�t�#d\qO+﮸��w���<��%���1.$/g���r��;��ҫ��hҒ�|&OגVy�ݯ��~I�f�[ݪ^���<э3 Z�h���ثG(��:*�y��c�����R�(��k�	�x���t��V{�k�
yFl%RǓ��o����=�������#q�K�O�4�K��bAl�<�S�y-Y��ҩj�\QB���A4��=��.	��b��/3�d*���R�(���ҟMGB)Ҧ�� �˱k���£+��y�L��"��/���"ɹ�op�> �}��%��u�e���D{~���.�3y>�/�{�/ZԬ�P�Oň�p��h7W�[c�<h�]�x�2�#�D��.�s�x�xu�}��	��'�G���)�א�׉W�mz��x��ˆ��1��z�h��R�q�p7%[m��⍖	j��k���s|�#.�d'C	q��x�6�>ox�"��L��CͲ4�`�M��Yp�g�E��Q� /��n�gy�~��z��D��Ϋ��_��h�����M�7�/�qP:v���} 芆ϐ׀R�G�Mm�
Hh(�֟�C����.�<��I�i�]�X�7�d,	�}��>eyXĚF�]}_���!�ýe�.��V��?Y�d�����`�ܿ��.ĚVy�v�]mv�"����X��h�p ��*Ek��#�,s�B�0ւrC�THҴ�hLH�dN��.� ��2��Sr[��U&�1�iKõsuhE��^�7�8�u���3�r�uZ���{�ޙ<�+ƅ"�����|�0�Kf�}!�H����db�,d�x�(�J�;�ߙ����X��r*�8�"R|��Hګ?�pv�b|�pb��¡��]�^���4�����.�VU}�K�����2�������q���9[^s)����#{1��f�����
���48 �k=9B�������~=��&��|���!��uz�p�c�X���\�$i\�V�����!\��sb��h�׏w�~?�B�O�8�;�ǎ�̨�vȚ��|���3��&�j�s����0�Y�\��$ػG�<.���V�"C�T`� �����,fA�'a�RA��q��G���(�?��s�c�J,�:}r��rC�H�y����j�+J����Wi�˭eju���R�� F�:K�=��]e�g�����˿����������c�ږTE��;_atG���rGN�D4 *�x���t "^AE���[驪S��]{uDw�bf�	+���{�c�	�
KK�:�F�;�7��E�H@S����|]�:�&Q��Y������
�_�fů��v�!�[A��_A뿨#�����+���o��4�����A�'����`5��OFX&)�D���La2���M��I��	��5��p^Ɍ���8l����XX��d��ڧ*7��O*����\۞�~�}Ew��Q��yi��+���A����[���7��	��\p33���Ȥ�������
����}��}�o�x�5J�{q�۷������eW ����w���_�P��)!�n�q~��י�Ǆ�(���_g����$|5� ��1䔄�������o�񜩋d�U��x�_t�)/,4*�����Z��lB��0�'�$��d$7���|���`uF;&�D�M·�9���qO&����%[)̭���W�P�G�?�=x%~�D��us�^@�����5F�{}W�E2֑V�&un����@�L��on��]�&�
�Kz�*�K�<�R�\D��\x��)�1���	#���Zd�9�Jn��saǢ|���|���=5�ݬ��Q�
l�w�^;�Mv&�`!���}��R��4m�DETx��\��R9��|x �����]���~/������_0���_݌B`��rC�����q��_J
ֶ�#�1�?&����X���d�E��a�l0��e4^�:�рGKe�p������rf���0v�Mi��WWg.�z�����fQhK��E�͹&�3��C�BY|5z�3�}l9��g�:,��B��$9��<�l�\�f�9ZJg"?O��D}�	6��i|���F𖪧��㹍��z���Ï����ҿ�9�����L=n,DUk.9�}�r�^����멹�.v&��>�W]Y~!�����Ԍ�}���P5��˹������҃���βܵ=w^$�.�&��P���oF�\�ϛ��nfu�Q���Ι\���b�xT�_��X/&��7��M�E���P���8���?���{���c_�>��W�
m�o{M���:�okxi�a\(.�¯9���g��u���
�^4oy���ۗ�Ng�SB]�<���֫����Ld�A�_���n
�i��g��8��C(��Q���{���f~mς��op�^��zxMF;~>���^����sUP�������-T۶l��69����1�	7c�o,����g�L�S�@��ج�	��9�Jw̉A*�Y���N������o�ZʟN�/���y,��@��8��=�̿y��j����������������N�F��(����q�1����������������?���@�7RO��' �= ��=~?����� �y��u��bp�C��񿧡�:~x�	�8�#|���MC��	�8�G�ܟ�2+�Uǟ���_8�/��b~�,�������_۶��uo}�7E�;wt��Fb@����H�?���q{��C�ǁ��?����A�������_,H�x����@�HA��SH�~����������_,���3��껁#ͣ#&?�|� 1t��J7���2yL7�<�:A1�ƐyCC�F�����/�4�����p�K,����M��ObY��R�3E���ꩁm�h��(�<�܉e�;�My�d���*WV.&��M������nEu��qȦQ�)�=j���`Fb����a�w>@��}]��;�)��M�%�C��y�z�O�f����B�@Yc��N,a��������!�?��'������"�����?��Ƃ4�?�>X�'���@l����Ǥ�����?y�����ǁ��?FO��2���������ć4��~�*Q� ��O��)���g���@��?��DcC\��Z�'�����(��ǁ��?K�	��p9m���Y�jv?����Llq6oܝ��>���R�{>��)����p{�qpm�����hE�:F*��z�^UںW�J�Җ�Z[�{�g��3��қ�Z���PV��z�z	S��^��t��=�R��k�*q|i��w|+�v��ҵ+[��<�˽)�҅1�k����U���̼��U����5�P
3`K�����Q��&= �}���i��W�<�@[8�@�m�,p����ܔ��	c=%�1S����z�n^�Ydݬ�<y�Z.Z�.�����2���2����Ϸቚ�"v�!��ܠA4WZ�o�y��R=67�Y� QF��u�.��9S2[�Lۋ��~hmq�����̦�<w�r]E'{�d����ir�����[Ra�a�!�#����Up����_��K�Sw���1!M����#�?����p�s,x��o���8����8��d��[6(g������C"����ۧ��v����L�g�����~����r?=�d��q����S�'2k�������J�i�/���8W�9�r����td��V�R���;s�劵�F�Y��4d|(����F�١����v��)����ϒ��W�#�e�7mn�������6Ioҳ�����h�\������inޙ�|_M�Evl~N��J�^g�%)8C��?ȕ�)H��ޡhu�ku�&W���v����Ν�eii�E�1R�]����-������Đ�/L�%�D ��׶�R�����R���3R��?�"i��� �?���?��S����?�8��ϙ��������_*��������������������Û��m���.�{���^��F4.ˍ��Nw��?x���|���ѯ��zo�����n=���~�^�,�����͍ި)�s���Us!�\���6Z!�hi�d�#g=�"��a-�U�G��Z�_kKTo��&]�*���ȭ_op
�~�x�	���K?兆'���6>r���6~�/�ِƜLN��Gd�ͷ�ӧ�[F�6��x���5_%�j�$�%��M�Z{G��f��H����l7+y��J��P��U��j��?���
�{`��`�Ł4�3c��� �?~������4�?�?����X�*��4��G6�QRyJ#�J��f���5F��NЄJ3:Nh:J�N,��
g�0������������*y���v=W�Uiı��v}`w��f��W��畩��H����[֖l���8�t�+ʝ���`²��Ǖ�z���7��e�!hΚ)��)N
�N�����=Ԗ9�2K��j�$uX���"�?�&���w��I"�?��!��?�!����L�7������%����6Ն���bvk�L�l!�AsDsK���*kQ����T�Z�coN��X!���zn¨սC?���SI%�12�Z]v��h�t���.t���~����&�n��9z��9T&smm@���^�c�'`�7!�a���?��?�s�HC��%����/����/X��/���@*�?�ٻ[�a���o���o���E��n�nI�Tc�xf*�&N�]�N�8MD���O��E�� ��5��3 ��ß8 ��g����z�;ק�CK	x� ���d�#s�lŵ	�`[���#��-�x�ɓ*Ek�j�%��Y���V���Y��>�Za-�<v�[o������bjt1��]όn!���W� ht����?��M����'�M�q`@W�r�4�F����-������)����Ѫ9U�#;�`3���g����ϒ�x�q៏ܟ4�s��$�+��z�,�����A���\�'��� U,ĦG�U�\:�Z���S��-�����݅��ɞ�Rzy���U,����O�jĥ;� �F>��@�/�0��*Dx�q��[�������8�����?������K+�����' �#��?����?��'���C�B����XU�)U�4�̣�Pb�A�ʪ�J�$k0h������@���a�5H��TZ5 ��W!����_� �/|f�mfi١���#�Dû]N��9���䁮*�ݠ�(���,h�KS��[�9UlK*�ͪ��f�&b-���,��s��q�����4�u�9?GtsSV:����K��u%E��}/�0�cԃ� �7�����Cҷ	�������(��ǁT�?}���1!&�W��	h������I�?�߭�����.��O�N���������������.\⿫��խf��_�����g��]��~H$������o������>C~&�;��F^����^��t��=ީ�ț�ߥM^���4۵�J׮l���/���K�H��~��Ve��2�fg�WeN.���dB)̀,�B��b$G֛��%ӓ��6_Q8��{����{0�e���pn~����xY7+3O^�����Kj��F�"�L�'�L���>*���#H�t������}�̫�걹�5�2�2ZV��u٭0̙�٢d�^T��C�h�KU�<�e6-乫��*:�$�l��N�KuXvlH���{����b���|�����m����q��O1�?��i����8��q �!��!���������;w`	 � ��k�i���O���'�������B�O, �_���_��M6��A�7�_�a��8A�I�(�!�������� ����'���@l��8�������<����I!i�q�d���8��xB���cA��!��?���O=8��?bA���!bF\�����?�� ���[�p�Ra�a�!�#����̐� ��׶�R���]��LH�CZH�H���H����X ��� ��� ��`�%e��8Dr ��k�����O)�������?P��@��@�����`���c,H���LL�O��m�/�O���O�ǁt�?��Ǎ4���� ���!��o���Ra�a�?�8��of��^����������'�����R���[�j0�6Bu&O��Q�5F:��u��	��(:?TQ� Q]���j���J����,����������zS��PF�'��T�=N�5�/���4&�J^����$�Nf�j\ma�F�ԛϷ�b��M�a�q��
�\o�ѩ6�Jgv(��=tɅ0���a"dw��7�Ԟ*���-㥉)�{VǶ7�n���
�;R(�Qca���V��kwwSIwxʐ���?�C��;�]�$������
����Đ�?V���&�_i�����g�u�P�]֭��b֒������<�͒��"V߹{n)Z�g�J�Ŷ�_��U����
��O�DlPT�_�iD�/�*��"��8{d��(���9�z/�_/Lw��]�g�n�=r���d�W�h4�{�yF��fl��x/�ۮ~����.n:K�)2�����^٬杙��P���X�����$�a��?��W���ԡ�濪�������?��*�@V�Z�?�|�����|�N�������O2�J�[v厜|~��9q��������U�)�D��D槏u �?*k��i�0T9����8�c�A��T�7��h�Ӡ�6�ފ�,���a3���9;�睰��ܶOI+f3�Lw�=��-}] ��n�\�k��ӭ����N_�
K�|�R�j��Չs�B~;,�&=���q'���@R|�8�f(�����=jSn;��~3�DKud����FP�ى$��ȧ~j�<�0@���q�����t��莦�Z�� �q�ءSA$�q�1h��P)�2��8��ug�)����p���������NP��[>���r��߿�I��/u��.������O�n��UW�q��������:�?y�����KAI����	��CY����ܝ��14�e�w��ݓeqz���aه���F	��AjMge��������"�����u�t]�ώ�r�Q�����s?,�x������q������S��˞o��պ�,)�Y�ݫuyu.��%��ؒaO�Iq���O�Ւ���P�+������9�p;*�a���R�����*�b4$���q��T�h/#��(�cc�]���E���tjq����ϳ���QOl?o��OVޓ��o۹��m-�x�^��ع�~���.O9̒�>S%vI��~k��P��lV���n�*��<`�A�!y�-�z�����2�vCT$UL$r�J\^"b�d��'��`(Nz�h$;�a���	����F,%}̓
�8����/,�=�3>Q1�^�z�I0ܶ�h�_�����������ߒP���|�Y��|.�	��
��4�B�ӗ�����)!�(�g&�C_ ��)Lv�P�?�����|d���Ƒؘ��F'�>����v<�;o�ͣ�v#��������˕�jy�\����+>���B������_���|�A�}����+e����W_������w�K��+���Z�������h��D�HÓ�r�;��;��������P�̓�w5ؐ�y�v?�xW�y��7�����k�|��퇼��s�d�6�Lhn�ʬ�*Y'��"�zxhN�%a����h��;��9XQ^�a�gz�;Nh1��y���812sp�����~7�y��y�z^&��ŉ؏tT�����F4��Ik�z6�qz��c�OLF�)�t�������{ሣ�Q�R��8�cN�L�E�4/?��ۋ�%"���
g�"D'�Ukh�Mk�bۓ��ү���P�G���@�SI(c�g<6����y�"�$�[~{y�pa�>���׃���0��Cz$�\�!x����P�������$|���5�e���1^���!GA��&z���W�v��Α��F�����l��佲������� �_�iX������5��7	�S�q����s4���Z�?{�����(�����?��ZG ��W����W����������������h��2��_�����8����a����o�T������{���}x�Kߒ�[�K��s_��8����,��-D��A,�#��R�2>�s�d+��^�/���)?�+s�u۹F޻u}۹F�����㗗g�}-������-�y��r6��|�˓���bo�iuȱ����`�8���-M������YK���p7)�ˉ@0��q����y�b[d��ƶ-5���X<���>��*[�X4��}���Z��ˣŬc�C��8�E�G��lӌe�
b���c˺i�E����u��hy�f0�;�>�fc����L5]�`"���L,�q�v{b"�J�����r#1TN��թة�0#R'p�';̚7�_9���������P��<(�k
���������oաT��F�ڡ��}�7��� ����������A�}��{ʀ �����{�:�?��W���� �Z����a��@�#�?B�#�?����>e�>���	��q��U��P���Z�?ww����������V�z ���z�����T���Q ��W��$q��翕�J�r!*�?���O?8���/u�ȅ�e�����X��(�� ����}Q��?�a��T��`(�r@����_-��z�� ����!����������@��?@��?��?����BT���������e��C.D5�E�� �����R ��� ���Pm�� ���-��<����Z@����_-��~�� �_��&�����?��W������������9�����4<��6��2@����_��"����-	����%	"�}��2^ �$�N�H C:��iD�Lr|H4D�/x��a�.���,����>�_u�����������;]cp)���TǷ�_o��*Z��K���Z�p��.�/��!�x�]�ǉY��ٳC���cd�٬Ǵ�&�	�B&R3Ļ޶�YW�nW��UԶI�d��(�J�>�c��;�ib�"�NM?`l�3%w�����Ě�c���OV�h�m21���d4�=!ŕ�L~�{wo��^3�a�����P���[��oP����P�����P)�?��?.e`՗�ۢ��_u���O�b���Z�C���#�D!���Ÿ-s��6��c�V�5�Aڞ��^�����o������o�Â��f��*�6ͨ?5=Ic槝�N7ss��d�oc�%����P���X�q�ߊP��xۯxU�=�E��U����/����/�@�U������{���_�m�ߓ�k��m;�m�,��^7B��J.9���?\��|���I���T�EJ�_�6��&�(Y���ap�i���i?k����m5B9^"�CtCt��x4E��:.�l����&�uɍ���9�^���q�a���W��%������z+5d���'-�����o�X�$'P����$9����+��=�E�m��o�TS������C^i>��41QEB<��d�]���u��c��v�Ke,��4=���*#�Ɵ�</���}qN�Z|������G�-ځ�{�������|�Q�G0��T>}��h��'ʸ������P��Q
j���������������?X*�?���O�w���X��2P-�_�����������?�`���RP=��:�����_9�3w�,�O)��C
d�(���n�#	��� �!���/j����/������ Y%��������?T���?�XjQ���������������c�ڽ<�:��d�\w�N��n���;���2�Q0O���
�}��������!�d��:���a�wdI���o�6�{�7����:T�s�t&��ge�D��js�=<4���K���4Y�IҜ�(/�0�3��'�����<Zjf��9���"�����"�~=_=/I��D�G:*P��y�z#��5w=��8=�M��ܯ���S��>ћ������G���,ob��1'_��"@���j��E���LZ�3z��ê54�&���p����f��1j��`��2T��^^�������{�Z�?��W�Z���Cp�D-���_p�c9��/����/�����g`��"T��~^�������{�Z�?C �W�:���� ��Q����+���E�����47�u�1ۉ�d��ӎ{֨����������B�o��}��E��nc
5����� �7�p8m�Ϊ鑳&o(^����4'ݬ�Z�7�����(7�1���<���qޝY�`���vlPl���n0�5`�| ��� �:�W3 �B,���t&����xPv��,�ٕ�L7� 'љ���}�ߑ�Ʌ���}�����љج���gYԏF�c�l����w����;��JB����!�U_�o	�������S�}�#�?���?-�\�Q\�^�	�N)�'#�Y�'2"I�B�"���(b����P�9rʲ��?���Q�t�'�����<���M87�W��O2�t��#l���n>�t�f�j�x'���?O�i="��!F�l��"��3����b��)c�,�<�>�&{����s�u�<6�I1R�h+�������n��uX�!��:T��_���
|o�a����:Ԃ����2T��/� ^�����wD�����_6�/����wtS¦8�`)�璽r��N�Ig�eR��ͭ�c]��l���e�B7[����h5���N�:`F85���æ'{u�S�mf�����#�Xg�γӲX��踢I��ފz��w�_���_�_� �������� �_0��_0���J�Ѐ����a(��w�ox���S��fA�W�N��(>��|u�����/3 ���7��x=��q��*��x���	��fT�{Z�=?HgZ8l�"�$Ũ`>�݉e�Ѷ7[Rm�љ�Z� �M�A��޴��\�����<��$O,΋Γ�ޫ�,ƒ��bq�s]t��TX��ȣ���������~3�y}���&����v��v�Hd}�Hx����ܕ�˫X�ˇ&���E�0��޵5%�D�g�+�FjJ�&�Z���bo��N9�ń�C�!��tD����4�x�ч�ݩ�
�}N}rn`�ˍ�y����z��'8p�\�{C�ڦ��9����}��+򣫭��im��L���G'�Q���P���N�:q>�C����:8+��Ã֗���y�W�8�T������N8�A���j�w��R�,��rE��Y�G$|fsƬ�W˵�0�ǘQoc�84j{��90�A��oU���uM��B�3�!s�8�)4q�$H��)�S�R�
�2Fr�0�����("�\��ҟ�o+u� :,̯�u�O�F���/���/7��B�k����oC|�_��͍�����VQ�����/�� Zډ�i+`�h^��1�>B̂���"b�v�&-!�i��="�kp���S���E6��Q��9pa���f��K��X'�>C����e(�2;�*�����bF�.8KB�	�S�<�n�O&�i--F(i��ֵYB56J��D�s�$t�0F�p�.�r9�N�KD�&g>	�5q�kY���q�S�,%�������*���׺u68�ԭ%�\�$��/�x\˹4"/����xHT���	��P��.��7�I�����u���b �RF�Z�lU���=��0�*\��졐'eLX���l��۽��_��� �ث��'�Ӟi]/�͚>@<q����ʺ�1�ޠ�>�p�;��^�T\� "������`aB�-�I
�d�ȋgX^�'�?R��]:��)��`�����C�oMc�B���)d��˂(�;��pM`���FQ� Ē�q��$I	,�~����GV�_�5���)J�C�~�dX$!!�P(-nВ�=$뵛v�ނ�8t��%��9u-���:aYӥ�ͪ�4!�8�F��_+e����H�����.n�'x��;�N���?�~}ތ��W��4�^���t���)D�3;=kе��N�f��nf}�3�Wf�D�i��2��$�o2̕�k�}�y�;������	e��V�Tl���Y��4���_B���	� 0 