/*************************************************************           
 ** File:   [USP_ILS_ADDSendILSRFQ]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to add ISL RFQ data into our database
 ** Purpose:         
 ** Date:   08/Feb/2024      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------    ---------		--------------------------------          
    1   08/Feb/2024    Rajesh Gami    Created
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_ILS_ADDSendILSRFQ]
	@tbl_ILSRFQPartType ILSRFQPartType READONLY,
	@ThirdPartyRFQId BIGINT =NULL,
	@RFQId varchar(50) = NULL,
	@PortalRFQId varchar(60) = NULL,
	@Name VARCHAR(50) = NULL,
	@TypeId int = NULL,
	@IntegrationPortalId int = NULL,
	@StatusId int = NULL,
	@Priority VARCHAR(50) = NULL,
	@QuoteWithinDays INT = NULL,
	@DeliverByDate DATETIME = NULL,
	@PreparedBy VARCHAR(50) = NULL,
	@AttachmentId BIGINT = NULL,
	@DeliverToAddress VARCHAR(MAX) = NULL,
	@BuyerComment VARCHAR(MAX) = NULL,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200)
AS
BEGIN
	  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	  BEGIN TRANSACTION
			DECLARE @LatestThirdPartyRFQId bigint, @LatestILSRFQDetailId bigint;	
			DECLARE @TypeName varchar(50) = (SELECT TOP 1 [Type] FROM DBO.IntegrationRFQType WITH(NOLOCK) WHERE IntegrationRFQTypeId = @TypeId);
			DECLARE @StatusName varchar(50) = (SELECT TOP 1 [Status] FROM DBO.IntegrationRFQStatus WITH(NOLOCK) WHERE IntegrationRFQStatusId = @StatusId)
			DECLARE @IntegrationPortal varchar(50) = (SELECT TOP 1 [Description] FROM DBO.IntegrationPortal WITH(NOLOCK) WHERE IntegrationPortalId = @IntegrationPortalId)

			INSERT INTO [dbo].[ThirdPartyRFQ]
           ([RFQId] ,[PortalRFQId],[Name],[IntegrationRFQTypeId],[TypeName],[IntegrationPortalId],[IntegrationPortal],[IntegrationRFQStatusId]
           ,[Status],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsDeleted],[IsActive])
			VALUES
           (@RFQId,@PortalRFQId,@Name,@TypeId,@TypeName,@IntegrationPortalId,@IntegrationPortal,@StatusId
		   ,@StatusName,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),0,1)

		   SET @LatestThirdPartyRFQId = SCOPE_IDENTITY();
		   /**** Insert data into the ILS RFQ Detail table *****/
	       INSERT INTO [dbo].[ILSRFQDetail]
			   ([ThirdPartyRFQId],[Priority],[QuoteWithinDays],[DeliverByDate],[PreparedBy],[AttachmentId],[DeliverToAddress] ,[BuyerComment]
			   ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsDeleted]  ,[IsActive])
		   VALUES
			   (@LatestThirdPartyRFQId,@Priority ,@QuoteWithinDays ,@DeliverByDate ,@PreparedBy ,@AttachmentId ,@DeliverToAddress ,@BuyerComment
			   ,@MasterCompanyId ,@CreatedBy ,@CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,0 ,1)
			
		   SET @LatestILSRFQDetailId = SCOPE_IDENTITY();


		   /**** Insert Into the ISL RFQ Part Table ****/
		   INSERT INTO [dbo].[ILSRFQPart]
           ([ILSRFQDetailId],[PartNumber],[AltPartNumber],[Exchange],[Description],[Qty],[Condition],[IsEmail],[IsFax]
		   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsDeleted],[IsActive])
		   SELECT @LatestILSRFQDetailId,PartNumber,AltPartNumber,Exchange,Description,Qty,Condition,IsEmail,IsFax
		   ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE() ,0 ,1	  
		   FROM @tbl_ILSRFQPartType

	  COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_ILS_ADDSendILSRFQ' 
            , @ProcedureParameters VARCHAR(3000) = '@RFQId = ''' + CAST(ISNULL(@RFQId, '') as varchar(100)) + ''',
														@PortalRFQId = ' + ISNULL(@PortalRFQId,'') + ', 
														@Name = ' + ISNULL(@Name,'') + ', 
														@TypeId = ' + ISNULL(@TypeId,'') + ', 
														@IntegrationPortalId = ' + ISNULL(@IntegrationPortalId,'') + ', 
														@StatusId = ' + ISNULL(@StatusId,'') + ', 
														@Priority = ' + ISNULL(@Priority,'') + ', 
														@QuoteWithinDays = ' + ISNULL(@QuoteWithinDays,'') + ', 
														@DeliverByDate = ' + ISNULL(@DeliverByDate,'') + ', 
														@PreparedBy = ' + ISNULL(@PreparedBy,'') + ', 
														@AttachmentId = ' + ISNULL(@AttachmentId,'') + ', 
														@DeliverToAddress = ' + ISNULL(@DeliverToAddress,'') + ', 
														@BuyerComment = ' + ISNULL(@BuyerComment,'') + ', 
														@MasterCompanyId = ' + ISNULL(@MasterCompanyId,'') + ', 
														@CreatedBy = ' + ISNULL(@CreatedBy,'') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END