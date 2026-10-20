-- AlterTable
ALTER TABLE "devices" ADD COLUMN     "hostCredentialAuthTag" TEXT,
ADD COLUMN     "hostCredentialCiphertext" TEXT,
ADD COLUMN     "hostCredentialIv" TEXT;
