
-- exec dbo.backup_to_s3 @DB_NAME='PowerAeroSuites' ,@S3_BUCKET_NAME='pasdbbackups', @BACKUP_TYPE='FULL'
CREATE   PROCEDURE [dbo].[backup_to_s3]
	@DB_NAME NVARCHAR(50), /* database name to backup */
	@S3_BUCKET_NAME NVARCHAR(MAX), /* s3 bucket name */
	@BACKUP_TYPE NVARCHAR(50) /* backup type  FULL */
AS 
BEGIN
	DECLARE @date NVARCHAR(MAX);
	DECLARE @backup_filename_path NVARCHAR(MAX);

	SELECT @date = REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50), GETDATE(),120),'-','_'),' ','_'),':','_')
	print  @date
	SELECT @backup_filename_path='arn:aws:s3:::'+ @S3_BUCKET_NAME +'/'+ @DB_NAME+'_FULL_'+ @date + '.bak'
	print  @backup_filename_path

	/* Backup to S3 */
	exec msdb.dbo.rds_backup_database
	@source_db_name=@DB_NAME,
	@s3_arn_to_backup_to=@backup_filename_path,
	@overwrite_s3_backup_file=1,
	@type=@BACKUP_TYPE;

	/* Get Status*/
	exec msdb.dbo.rds_task_status;
END