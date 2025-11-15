function diskbackup --description 'Backup any HDD/SSD/USB Storage into a compressed archive.'
set gr (set_color brgreen)
set br (set_color -o red)
set bw (set_color -o white)
set wi (set_color FFF)
set no (set_color normal)
    sudo -v
    clear
    sudo fdisk -l $argv
    echo ""
    echo ""
    echo "______________________________________________________________________________"
    echo ""
    echo $bw" Backup Disks with dd and save md5 checksum"$no
    echo ""
    echo " Currently using  $bw$PWD/$no  for storing the Backup."
    echo " Do you want to change the folder where the backup will be saved?"
    while read -n 1 -l changefolder -P $gr" Change Backupfolder?$no (y/N) "
        or return 1
        switch $changefolder
                case y Y
                        echo ""
                        echo " Tab completion enabled. Enter Path like this: /home/user/custom/folder/"
                        echo " Folder will be created if it doesnt exist."
                        read -S -l customfolder -P $gr" Enter full Path now: "$no
                        or return 1
                        mkdir -pv $customfolder
                        set backupfolder $customfolder
                        break
                case n N
                        set backupfolder $PWD/
                        break
                case '*'
                        echo " Answer only with y for yes or n for no. Try again."
                        continue
        end
    end
    echo ""
    echo " Backup will be stored at:  $bw$backupfolder$no"
    echo ""
    echo " What's the name of the Device/Disk? Which OS is installed?"
    echo " This will be used for the Backup name. (E.g Server.Debian12)"
    read -l namebackup -P $gr" Backup Name: "$no
    or return 1
    set -gx backupname $namebackup".img"
    echo ""
    echo " Which Disk do you want to backup? See fdisk output above. (E.g sda, nvme1n1)"
    read -l whichdisk -P $gr" Enter Disk name: "$no
    or return 1
    set -gx table (sudo fdisk -l /dev/$whichdisk | string split0) #store multi line output
    # Get blocksize for dd backup
    sudo /usr/sbin/blockdev --getbsz /dev/$whichdisk | read block
    set -gx md5file $backupfolder$namebackup".md5"
    echo ""
    echo " How many Partitions to backup? Select 0-6. (This is only for the md5 cheksums.)"
    echo " Note: 0 meaning only a single Partition, not a whole Disk with all Partitions."
    while read -l manypartitions -P $gr" How many Partitions? "$no
        or return 1
        switch $manypartitions
            case 0
                echo " You selected $manypartitions Partitions!"
                echo " Enter the Partition you want to backup. (E.g sda3, nvme1n1p2)"
                read -l partition1 -P $gr" Which Partition? "$no
                echo ""
                echo " Print a present md5 checksum for comparision or need to create one first?"
                while read -n 1 -l answermd5 -P $bw" C"$no$gr"reate or "$bw"P"$no$gr"rint?$no (c/P) "
                    or return 1
                    switch $answermd5
                        case c C
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Get and print md5 checksums from Disk
                            echo "Backup created on: "(date "+%d/%m/%Y") > $md5file
                            echo "" >> $md5file
                            echo "Getting md5 checksum from $partition1 ..."
                            sudo md5sum /dev/$partition1 >> $md5file
                            or return 1
                            cat $md5file | sed 3!d | read sum1
                            echo "   "$br$sum1$no
                            echo "" >> $md5file
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $bw$block$no ..."
                            sudo dd if=/dev/$partition1 conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 5!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case p P
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Print existing md5.txt
                            echo "Printing md5checksum..."
                            cat $md5file | sed 3!d | read checksums
                            echo "   "$br$checksums$no
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $block ..."
                            sudo dd if=/dev/$partition1 conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            echo "" >> $md5file
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 5!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case '*'
                            echo " Answer only with "$bw"c"$no" for Copy or "$bw"p"$no" for Print. Try again."
                            continue
                    end
                end
                break
            case 1
                switch $whichdisk
                    case "nvme*"
                        set partition1 $whichdisk"p1"
                    case "sd*"
                        set partition1 $whichdisk"1"
                end
                echo " You selected $manypartitions Partitions!"
                echo ""
                echo " Print a present md5 checksum for comparision or need to create one first?"
                while read -n 1 -l answermd5 -P $bw" C"$no$gr"reate or "$bw"P"$no$gr"rint?$no (c/P) "
                    or return 1
                    switch $answermd5
                        case c C
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Get and print md5 checksums from Disk
                            echo "Backup created on: "(date "+%d/%m/%Y") > $md5file
                            echo "" >> $md5file
                            echo "Getting md5 checksum from $whichdisk ..."
                            sudo md5sum /dev/$whichdisk >> $md5file
                            or return 1
                            cat $md5file | sed 3!d | read sum1
                            echo "   "$br$sum1$no
                            echo "Getting md5 checksum from $partition1 ..."
                            sudo md5sum /dev/$partition1 >> $md5file
                            or return 1
                            cat $md5file | sed 4!d | read sum2
                            echo "   "$bw$sum2$no
                            echo "" >> $md5file
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $bw$block$no ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 6!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case p P
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Print existing md5.txt
                            echo "Printing md5checksum..."
                            cat $md5file | sed 3!d | read checksums
                            echo "   "$br$checksums$no
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $block ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            echo "" >> $md5file
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 6!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case '*'
                            echo " Answer only with "$bw"c"$no" for Copy or "$bw"p"$no" for Print. Try again."
                            continue
                    end
                end
                break
            case 2
                switch $whichdisk
                    case "nvme*"
                        set partition1 $whichdisk"p1"
                        set partition2 $whichdisk"p2"
                    case "sd*"
                        set partition1 $whichdisk"1"
                        set partition2 $whichdisk"2"
                end
                echo " You selected $manypartitions Partitions!"
                echo ""
                echo " Print a present md5 checksum for comparision or need to create one first?"
                while read -n 1 -l answermd5 -P $bw" C"$no$gr"reate or "$bw"P"$no$gr"rint?$no (c/P) "
                    or return 1
                    switch $answermd5
                        case c C
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Get and print md5 checksums from Disk
                            echo "Backup created on: "(date "+%d/%m/%Y") > $md5file
                            echo "" >> $md5file
                            echo "Getting md5 checksum from $whichdisk ..."
                            sudo md5sum /dev/$whichdisk >> $md5file
                            or return 1
                            cat $md5file | sed 3!d | read sum1
                            echo "   "$br$sum1$no
                            echo "Getting md5 checksum from $partition1 ..."
                            sudo md5sum /dev/$partition1 >> $md5file
                            or return 1
                            cat $md5file | sed 4!d | read sum2
                            echo "   "$bw$sum2$no
                            echo "Getting md5 checksum from $partition2 ..."
                            sudo md5sum /dev/$partition2 >> $md5file
                            or return 1
                            cat $md5file | sed 5!d | read sum3
                            echo "   "$bw$sum3$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $bw$block$no ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 7!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case p P
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Print existing md5.txt
                            echo "Printing md5checksum..."
                            cat $md5file | sed 3!d | read checksums
                            echo "   "$br$checksums$no
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $block ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            echo "" >> $md5file
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 7!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case '*'
                            echo " Answer only with "$bw"c"$no" for Copy or "$bw"p"$no" for Print. Try again."
                            continue
                    end
                end
                break
            case 3
                switch $whichdisk
                    case "nvme*"
                        set partition1 $whichdisk"p1"
                        set partition2 $whichdisk"p2"
                        set partition3 $whichdisk"p3"
                    case "sd*"
                        set partition1 $whichdisk"1"
                        set partition2 $whichdisk"2"
                        set partition3 $whichdisk"3"
                end
                echo " You selected $manypartitions Partitions!"
                echo ""
                echo " Print a present md5 checksum for comparision or need to create one first?"
                while read -n 1 -l answermd5 -P $bw" C"$no$gr"reate or "$bw"P"$no$gr"rint?$no (c/P) "
                    or return 1
                    switch $answermd5
                        case c C
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Get and print md5 checksums from Disk
                            echo "Backup created on: "(date "+%d/%m/%Y") > $md5file
                            echo "" >> $md5file
                            echo "Getting md5 checksum from $whichdisk ..."
                            sudo md5sum /dev/$whichdisk >> $md5file
                            or return 1
                            cat $md5file | sed 3!d | read sum1
                            echo "   "$br$sum1$no
                            echo "Getting md5 checksum from $partition1 ..."
                            sudo md5sum /dev/$partition1 >> $md5file
                            or return 1
                            cat $md5file | sed 4!d | read sum2
                            echo "   "$bw$sum2$no
                            echo "Getting md5 checksum from $partition2 ..."
                            sudo md5sum /dev/$partition2 >> $md5file
                            or return 1
                            cat $md5file | sed 5!d | read sum3
                            echo "   "$bw$sum3$no
                            echo "Getting md5 checksum from $partition3 ..."
                            sudo md5sum /dev/$partition3 >> $md5file
                            or return 1
                            cat $md5file | sed 6!d | read sum4
                            echo "   "$bw$sum4$no
                            echo "" >> $md5file
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $bw$block$no ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 8!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case p P
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Print existing md5.txt
                            echo "Printing md5checksum..."
                            cat $md5file | sed 3!d | read checksums
                            echo "   "$br$checksums$no
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $block ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            echo "" >> $md5file
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 8!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case '*'
                            echo " Answer only with "$bw"c"$no" for Copy or "$bw"p"$no" for Print. Try again."
                            continue
                    end
                end
                break
            case 4
                switch $whichdisk
                    case "nvme*"
                        set partition1 $whichdisk"p1"
                        set partition2 $whichdisk"p2"
                        set partition3 $whichdisk"p3"
                        set partition4 $whichdisk"p4"
                    case "sd*"
                        set partition1 $whichdisk"1"
                        set partition2 $whichdisk"2"
                        set partition3 $whichdisk"3"
                        set partition4 $whichdisk"4"
                end
                echo " You selected $manypartitions Partitions!"
                echo ""
                echo " Print a present md5 checksum for comparision or need to create one first?"
                while read -n 1 -l answermd5 -P $bw" C"$no$gr"reate or "$bw"P"$no$gr"rint?$no (c/P) "
                    or return 1
                    switch $answermd5
                        case c C
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Get and print md5 checksums from Disk
                            echo "Backup created on: "(date "+%d/%m/%Y") > $md5file
                            echo "" >> $md5file
                            echo "Getting md5 checksum from $whichdisk ..."
                            sudo md5sum /dev/$whichdisk >> $md5file
                            or return 1
                            cat $md5file | sed 3!d | read sum1
                            echo "   "$br$sum1$no
                            echo "Getting md5 checksum from $partition1 ..."
                            sudo md5sum /dev/$partition1 >> $md5file
                            or return 1
                            cat $md5file | sed 4!d | read sum2
                            echo "   "$bw$sum2$no
                            echo "Getting md5 checksum from $partition2 ..."
                            sudo md5sum /dev/$partition2 >> $md5file
                            or return 1
                            cat $md5file | sed 5!d | read sum3
                            echo "   "$bw$sum3$no
                            echo "Getting md5 checksum from $partition3 ..."
                            sudo md5sum /dev/$partition3 >> $md5file
                            or return 1
                            cat $md5file | sed 6!d | read sum4
                            echo "   "$bw$sum4$no
                            echo "Getting md5 checksum from $partition4 ..."
                            sudo md5sum /dev/$partition4 >> $md5file
                            or return 1
                            cat $md5file | sed 7!d | read sum5
                            echo "   "$bw$sum5$no
                            echo "" >> $md5file
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $bw$block$no ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 9!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case p P
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Print existing md5.txt
                            echo "Printing md5checksum..."
                            cat $md5file | sed 3!d | read checksums
                            echo "   "$br$checksums$no
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $block ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            echo "" >> $md5file
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 9!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case '*'
                            echo " Answer only with "$bw"c"$no" for Copy or "$bw"p"$no" for Print. Try again."
                            continue
                    end
                end
                break
            case 5
                switch $whichdisk
                    case "nvme*"
                        set partition1 $whichdisk"p1"
                        set partition2 $whichdisk"p2"
                        set partition3 $whichdisk"p3"
                        set partition4 $whichdisk"p4"
                        set partition5 $whichdisk"p5"
                    case "sd*"
                        set partition1 $whichdisk"1"
                        set partition2 $whichdisk"2"
                        set partition3 $whichdisk"3"
                        set partition4 $whichdisk"4"
                        set partition5 $whichdisk"5"
                end
                echo " You selected $manypartitions Partitions!"
                echo ""
                echo " Print a present md5 checksum for comparision or need to create one first?"
                while read -n 1 -l answermd5 -P $bw" C"$no$gr"reate or "$bw"P"$no$gr"rint?$no (c/P) "
                    or return 1
                    switch $answermd5
                        case c C
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Get and print md5 checksums from Disk
                            echo "Backup created on: "(date "+%d/%m/%Y") > $md5file
                            echo "" >> $md5file
                            echo "Getting md5 checksum from $whichdisk ..."
                            sudo md5sum /dev/$whichdisk >> $md5file
                            or return 1
                            cat $md5file | sed 3!d | read sum1
                            echo "   "$br$sum1$no
                            echo "Getting md5 checksum from $partition1 ..."
                            sudo md5sum /dev/$partition1 >> $md5file
                            or return 1
                            cat $md5file | sed 4!d | read sum2
                            echo "   "$bw$sum2$no
                            echo "Getting md5 checksum from $partition2 ..."
                            sudo md5sum /dev/$partition2 >> $md5file
                            or return 1
                            cat $md5file | sed 5!d | read sum3
                            echo "   "$bw$sum3$no
                            echo "Getting md5 checksum from $partition3 ..."
                            sudo md5sum /dev/$partition3 >> $md5file
                            or return 1
                            cat $md5file | sed 6!d | read sum4
                            echo "   "$bw$sum4$no
                            echo "Getting md5 checksum from $partition4 ..."
                            sudo md5sum /dev/$partition4 >> $md5file
                            or return 1
                            cat $md5file | sed 7!d | read sum5
                            echo "   "$bw$sum5$no
                            echo "Getting md5 checksum from $partition5 ..."
                            sudo md5sum /dev/$partition5 >> $md5file
                            or return 1
                            cat $md5file | sed 8!d | read sum6
                            echo "   "$bw$sum6$no
                            echo "" >> $md5file
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $bw$block$no ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo "Getting md5 checksum from $backupname ..."
                            echo ""
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 10!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case p P
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Print existing md5.txt
                            echo "Printing md5checksum..."
                            cat $md5file | sed 3!d | read checksums
                            echo "   "$br$checksums$no
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $block ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            echo "" >> $md5file
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 10!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case '*'
                            echo " Answer only with "$bw"c"$no" for Copy or "$bw"p"$no" for Print. Try again."
                            continue
                    end
                end
                break
            case 6
                switch $whichdisk
                    case "nvme*"
                        set partition1 $whichdisk"p1"
                        set partition2 $whichdisk"p2"
                        set partition3 $whichdisk"p3"
                        set partition4 $whichdisk"p4"
                        set partition5 $whichdisk"p5"
                        set partition6 $whichdisk"p6"
                    case "sd*"
                        set partition1 $whichdisk"1"
                        set partition2 $whichdisk"2"
                        set partition3 $whichdisk"3"
                        set partition4 $whichdisk"4"
                        set partition5 $whichdisk"5"
                        set partition6 $whichdisk"6"
                end
                echo " You selected $manypartitions Partitions!"
                echo ""
                echo " Print a present md5 checksum for comparision or need to create one first?"
                while read -n 1 -l answermd5 -P $bw" C"$no$gr"reate or "$bw"P"$no$gr"rint?$no (c/P) "
                    or return 1
                    switch $answermd5
                        case c C
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Get and print md5 checksums from Disk
                            echo "Backup created on: "(date "+%d/%m/%Y") > $md5file
                            echo "" >> $md5file
                            echo "Getting md5 checksum from $whichdisk ..."
                            sudo md5sum /dev/$whichdisk >> $md5file
                            or return 1
                            cat $md5file | sed 3!d | read sum1
                            echo "   "$br$sum1$no
                            echo "Getting md5 checksum from $partition1 ..."
                            sudo md5sum /dev/$partition1 >> $md5file
                            or return 1
                            cat $md5file | sed 4!d | read sum2
                            echo "   "$bw$sum2$no
                            echo "Getting md5 checksum from $partition2 ..."
                            sudo md5sum /dev/$partition2 >> $md5file
                            or return 1
                            cat $md5file | sed 5!d | read sum3
                            echo "   "$bw$sum3$no
                            echo "Getting md5 checksum from $partition3 ..."
                            sudo md5sum /dev/$partition3 >> $md5file
                            or return 1
                            cat $md5file | sed 6!d | read sum4
                            echo "   "$bw$sum4$no
                            echo "Getting md5 checksum from $partition4 ..."
                            sudo md5sum /dev/$partition4 >> $md5file
                            or return 1
                            cat $md5file | sed 7!d | read sum5
                            echo "   "$bw$sum5$no
                            echo "Getting md5 checksum from $partition5 ..."
                            sudo md5sum /dev/$partition5 >> $md5file
                            or return 1
                            cat $md5file | sed 8!d | read sum6
                            echo "   "$bw$sum6$no
                            echo "Getting md5 checksum from $partition6 ..."
                            sudo md5sum /dev/$partition6 >> $md5file
                            or return 1
                            cat $md5file | sed 9!d | read sum7
                            echo "   "$bw$sum7$no
                            echo "" >> $md5file
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $bw$block$no ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 11!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case p P
                            echo ""
                            echo "______________________________________________________________________________"
                            echo ""
                            # Print existing md5.txt
                            echo "Printing md5checksum..."
                            cat $md5file | sed 3!d | read checksums
                            echo "   "$br$checksums$no
                            echo ""
                            # Create Backup and compress it
                            echo "Creating compressed Backup with blocksize $block ..."
                            sudo dd if=/dev/$whichdisk conv=sync bs=$block status=progress | xz -9 -z - > $backupfolder$backupname.xz
                            or return 1
                            # Get and print md5 checksums from Archived-Image
                            echo ""
                            echo "Getting md5 checksum from $backupname ..."
                            echo "" >> $md5file
                            xzcat $backupfolder$backupname.xz | md5sum >> $md5file # Get md5 checksum from backup-image inside the archive
                            sed -i "s/-/$backupname/" $md5file # replacing the dash with the backup-image name
                            cat $md5file | sed 11!d | read sum0
                            echo "   "$br$sum0$no
                            echo "_________________________________________________________________________________" >> $md5file
                            echo "" >> $md5file
                            echo $table >> $md5file
                            echo ""
                            echo $bw"All Done! (=^•ω•^=)v"$no
                            break
                        case '*'
                            echo " Answer only with "$bw"c"$no" for Copy or "$bw"p"$no" for Print. Try again."
                            continue
                    end
                end
                break
            case '*'
                echo " Invalid input, try again."
                echo " Note: Only up to 6 Partitions are supported."
                continue
        end
    end
  echo """
  _________________________________________________________________________
  |                                                                       |
  | $bw Note:$no Backup too big? Delete some files & fill empty space with 0's  |
  |  dd if=/dev/zero of=$wi/dir/to/mountpoint/delete.me$no status=progress      |
  |                                                                       |
  |_______________________________________________________________________|
  | $br Make sure to double check its the right output location in$bw of=$no       |
  | $br or else you might destroy the content of a Disk!$no                     |
  |                                                                       |
  | $bw Restore the Disk Backup with dd/xzcat$no                                |
  |  xzcat backup-archive.xz | sudo dd of=/dev/sdX status=progress        |
  |                                                                       |
  | $bw Check the Partitions afterwards with md5sum & compare to backup.md5$no  |
  |  cat backup-archive.md5                                               |
  |  sudo md5sum /dev/sdX                                                 |
  |  sudo md5sum /dev/sdXX                                                |
  |_______________________________________________________________________|
  """
end
