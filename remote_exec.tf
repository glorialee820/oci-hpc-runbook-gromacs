resource "null_resource" "remote-exec-GPU" {
  count      = var.gpu_node_count
  depends_on = [oci_core_instance.GPU_Instance]

  provisioner "file" {
    destination = "/home/${local.os_user}/.ssh/id_rsa"
    source = "key.pem"

    connection {
    timeout = "15m"
    host = data.oci_core_vnic.GPU_Instance_Primary_VNIC[count.index].public_ip_address
    user = local.os_user
    private_key = tls_private_key.key.private_key_pem
    agent = false
    }
  }

  provisioner "file" {
    destination = "/home/${local.os_user}/gpu-start.sh"
    source = "gpu-start.sh"

    connection {
    timeout = "15m"
    host = data.oci_core_vnic.GPU_Instance_Primary_VNIC[count.index].public_ip_address
    user = local.os_user
    private_key = tls_private_key.key.private_key_pem
    agent = false
    }
  }

  provisioner "file" {
    destination = "/home/${local.os_user}/visualization.sh"
    source = "visualization.sh"

    connection {
    timeout = "15m"
    user = local.os_user
    host = data.oci_core_vnic.GPU_Instance_Primary_VNIC[count.index].public_ip_address
    private_key = tls_private_key.key.private_key_pem
    agent = false
    }
  }

  provisioner "remote-exec" {
    connection {
      agent       = false
      timeout     = "15m"
      host        = data.oci_core_vnic.GPU_Instance_Primary_VNIC[count.index].public_ip_address
      user        = local.os_user
      private_key = tls_private_key.key.private_key_pem    
    }

    inline = [
    "sudo chmod 755 ~/gpu-start.sh",
    "~/gpu-start.sh ${oci_core_virtual_network.GPU_VCN.cidr_block} \"${element(concat(oci_core_volume_attachment.GPU_BlockAttach.*.iqn, list("")), 0)}\" ${element(concat(oci_core_volume_attachment.GPU_BlockAttach.*.ipv4, list("")), 0)}:${element(concat(oci_core_volume_attachment.GPU_BlockAttach.*.port, list("")), 0)} | tee ~/gpu-start.log",
    "mv ~/gpu-start.log /mnt/block/logs/",
    ]
  }
}