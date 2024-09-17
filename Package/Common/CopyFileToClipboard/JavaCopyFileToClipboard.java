// Modified from http://stackoverflow.com/questions/31798646/can-java-system-clipboard-copy-a-file

import java.awt.Toolkit;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.ClipboardOwner;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class JavaCopyFileToClipboard {

	public JavaCopyFileToClipboard() {
	}

    public void copy(String[] args) {
		List listOfFiles = new ArrayList();
		for (String arg : args) {
			File file = new File(arg);
			listOfFiles.add(file);
		}
        
        FileTransferable ft = new FileTransferable(listOfFiles);

        Toolkit.getDefaultToolkit().getSystemClipboard().setContents(ft, new ClipboardOwner() {
           @Override
           public void lostOwnership(Clipboard clipboard, Transferable contents) {
				//System.out.println("Lost ownership");
		   }
        });
		
    }

    public static class FileTransferable implements Transferable {

        private List listOfFiles;

        public FileTransferable(List listOfFiles) {
            this.listOfFiles = listOfFiles;
        }

        @Override
        public DataFlavor[] getTransferDataFlavors() {
            return new DataFlavor[]{DataFlavor.javaFileListFlavor};
        }

        @Override
        public boolean isDataFlavorSupported(DataFlavor flavor) {
            return DataFlavor.javaFileListFlavor.equals(flavor);
        }

        @Override
        public Object getTransferData(DataFlavor flavor) throws UnsupportedFlavorException, IOException {
            return listOfFiles;
        }
    }

}