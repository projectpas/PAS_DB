/*************************************************************           
 ** File:   [dbo].[sp_VendorRMA_savePickTicketItemInterface]          
 ** Author:   Amit Ghediya
 ** Description: Save pick ticket stockline data to pick for Vendor RMA.
 ** Date: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    06/22/2023   Amit Ghediya			 created
	2    06/28/2023   Amit Ghediya			 Status remove for as it is.
	2    06/28/2023   Devendra Shekh		 added @QtyRemaining for insert and update

**************************************************************/ 
CREATE   PROCEDURE [dbo].[sp_VendorRMA_savePickTicketItemInterface]    
(    
  @RMAPickTicketId bigint = 0,
  @RMAPickTicketNumber varchar(100)='',
  @VendorRMAId bigint=0,
  @CreatedBy varchar(100)='',
  @UpdatedBy varchar(100)='',
  @IsActive bit =0,
  @IsDeleted bit =0,
  @VendorRMADetailId bigint=0,
  @Qty int = 0,
  @QtyToShip int=0,
  @MasterCompanyId int=0,
  @Status int=0,
  @PickedById int=0,
  @ConfirmedById int=0,
  @Memo varchar(MAX)='',
  @IsConfirmed bit=0,
  @CodePrefixId bigint,
  @CurrentNummber bigint = 0
)    
AS    
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @VendorRMAPartId BIGINT;
		DECLARE @QtyRemaining BIGINT; 

		IF(@RMAPickTicketId = 0)
		BEGIN

		SELECT @QtyRemaining = (vra.Qty - @QtyToShip - SUM(ISNULL(rmp.QtyToShip, 0))) 
		FROM VendorRMADetail vra WITH(NOLOCK)
		--INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON vra.VendorRMAId = sorpp.SalesOrderId AND vra.ved = sorpp.SalesOrderPartId   
		LEFT JOIN RMAPickTicket rmp WITH(NOLOCK) ON vra.VendorRMAId = rmp.VendorRMAId and vra.VendorRMADetailId = rmp.VendorRMADetailId
		WHERE vra.VendorRMAId = @VendorRMAId AND vra.VendorRMADetailId = @VendorRMADetailId GROUP BY vra.Qty

			INSERT INTO [dbo].[RMAPickTicket]
					([RMAPickTicketNumber], [VendorRMAId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive],
					[IsDeleted], [VendorRMADetailId], [Qty], [QtyToShip], [MasterCompanyId], [Status],
					[PickedById], [ConfirmedById], [Memo], [IsConfirmed], [QtyRemaining])
			VALUES(@RMAPickTicketNumber, @VendorRMAId, @CreatedBy, @UpdatedBy, GETDATE(), GETDATE(), @IsActive, @IsDeleted, 
					@VendorRMADetailId,
					@Qty, @QtyToShip, @MasterCompanyId, @Status, @PickedById, @ConfirmedById, @Memo, @IsConfirmed, @QtyRemaining);

			IF(@CodePrefixId > 0 AND @CurrentNummber > 0)
			BEGIN
				UPDATE DBO.CodePrefixes SET CurrentNummber = @CurrentNummber WHERE CodePrefixId = @CodePrefixId;
			END
		END
		ELSE IF(@RMAPickTicketId > 0 AND @IsConfirmed = 0)
		BEGIN
			UPDATE [dbo].[RMAPickTicket] SET QtyToShip = @QtyToShip,UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() WHERE RMAPickTicketId = @RMAPickTicketId;

			SELECT @QtyRemaining = (vra.Qty - SUM(ISNULL(rmp.QtyToShip, 0))) 
			FROM VendorRMADetail vra WITH(NOLOCK)
			--INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON vra.VendorRMAId = sorpp.SalesOrderId AND vra.ved = sorpp.SalesOrderPartId   
			LEFT JOIN RMAPickTicket rmp WITH(NOLOCK) ON vra.VendorRMAId = rmp.VendorRMAId and vra.VendorRMADetailId = rmp.VendorRMADetailId
			WHERE vra.VendorRMADetailId = @VendorRMADetailId GROUP BY vra.Qty

			UPDATE [dbo].[RMAPickTicket] SET QtyToShip = @QtyToShip,UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE(), [QtyRemaining] = @QtyRemaining WHERE RMAPickTicketId = @RMAPickTicketId;

			--Update [dbo].[VendorRMADetail] SET VendorRMAStatusId = (SELECT VendorRMAStatusId FROM DBO.VendorRMAHeaderStatus WITH (NOLOCK) WHERE Code = 'Pending') --(SELECT VendorRMAStatusId FROM DBO.VendorRMAStatus WITH (NOLOCK) WHERE Code = 'RS') 
			--WHERE VendorRMADetailId = @VendorRMADetailId;

			--Update [dbo].[VendorRMA] SET VendorRMAStatusId = (SELECT VendorRMAStatusId FROM DBO.VendorRMAHeaderStatus WITH (NOLOCK) WHERE Code = 'Pending') 
			--WHERE VendorRMAId = @VendorRMAId
		END
		ELSE IF(@RMAPickTicketId > 0 AND @IsConfirmed = 1)
		BEGIN
			UPDATE [dbo].[RMAPickTicket] SET ConfirmedById = @ConfirmedById, IsConfirmed = @IsConfirmed, ConfirmedDate = GETDATE() WHERE RMAPickTicketId = @RMAPickTicketId;

			
			SELECT @VendorRMAPartId = VendorRMADetailId FROM [dbo].[RMAPickTicket] WITH (NOLOCK) WHERE RMAPickTicketId = @RMAPickTicketId;

			--Update [dbo].[VendorRMADetail] SET VendorRMAStatusId = (SELECT VendorRMAStatusId FROM DBO.VendorRMAHeaderStatus WITH (NOLOCK) WHERE Code = 'Pending') --(SELECT VendorRMAStatusId FROM DBO.VendorRMAStatus WITH (NOLOCK) WHERE Code = 'SV') 
			--WHERE VendorRMADetailId = @VendorRMAPartId;

			--Update [dbo].[VendorRMA] SET VendorRMAStatusId = (SELECT VendorRMAStatusId FROM DBO.VendorRMAHeaderStatus WITH (NOLOCK) WHERE Code = 'Pending') 
			--WHERE VendorRMAId = @VendorRMAId;
		END
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_VendorRMA_savePickTicketItemInterface' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RMAPickTicketId, '') + ''
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