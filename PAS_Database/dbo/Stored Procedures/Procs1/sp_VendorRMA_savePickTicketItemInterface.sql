/*************************************************************           
 ** File:   [dbo].[sp_VendorRMA_savePickTicketItemInterface]          
 ** Author:   Amit Ghediya
 ** Description: Save pick ticket stockline data to pick for Vendor RMA.
 ** Date: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/22/2023   Amit Ghediya		created
	2    06/28/2023   Amit Ghediya		Status remove for as it is.
	3    06/28/2023   Devendra Shekh	added @QtyRemaining for insert and update
	4    07/08/2025   Vishal Suthar		Bypass Vendor RMA Pickticket Confirmation When Config Flag is Enabled
	5    02-03-2026	  Amit Ghediya		UOM Conversion Changes [PN-15140]

**************************************************************/
CREATE   PROCEDURE [dbo].[sp_VendorRMA_savePickTicketItemInterface]
(    
  @RMAPickTicketId bigint = 0,
  @RMAPickTicketNumber varchar(100) = '',
  @VendorRMAId bigint = 0,
  @CreatedBy varchar(100) = '',
  @UpdatedBy varchar(100) = '',
  @IsActive bit = 0,
  @IsDeleted bit = 0,
  @VendorRMADetailId bigint=0,
  @Qty decimal(18,6) = 0,
  @QtyToShip decimal(18,6) = 0,
  @MasterCompanyId int = 0,
  @Status int = 0,
  @PickedById int = 0,
  @ConfirmedById int = 0,
  @Memo varchar(MAX) = '',
  @IsConfirmed bit = 0,
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
		DECLARE @EnforcePickTicketConfirmation BIT;
		DECLARE @StockUnitOfMeasure VARCHAR(100) = NULL;
		DECLARE @PurchaseUnitOfMeasure VARCHAR(100) = NULL;

		SELECT @EnforcePickTicketConfirmation = EnforcePickTicketConfirmation FROM DBO.VendorRMASettings WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;

		SELECT @StockUnitOfMeasure = IM.StockUnitOfMeasure,
			   @PurchaseUnitOfMeasure = IM.PurchaseUnitOfMeasure
		FROM VendorRMADetail VR WITH(NOLOCK)
		INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
		INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId]
		WHERE VR.VendorRMADetailId = @VendorRMADetailId;

		IF(@RMAPickTicketId = 0)
		BEGIN

		SELECT @QtyRemaining = (ISNULL(vra.Qty, 0) - ([dbo].[fn_ConvertUOM](ISNULL(@QtyToShip, 0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])) - SUM(ISNULL(([dbo].[fn_ConvertUOM](ISNULL(rmp.QtyToShip, 0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])), 0))) 
		FROM VendorRMADetail vra WITH(NOLOCK)
		--INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON vra.VendorRMAId = sorpp.SalesOrderId AND vra.ved = sorpp.SalesOrderPartId   
		LEFT JOIN RMAPickTicket rmp WITH(NOLOCK) ON vra.VendorRMAId = rmp.VendorRMAId and vra.VendorRMADetailId = rmp.VendorRMADetailId
		INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = vra.[StockLineId]
		INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId]
		WHERE vra.VendorRMAId = @VendorRMAId AND vra.VendorRMADetailId = @VendorRMADetailId GROUP BY vra.Qty,IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],IM.[MasterCompanyId]

			INSERT INTO [dbo].[RMAPickTicket]
					([RMAPickTicketNumber], [VendorRMAId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive],
					[IsDeleted], [VendorRMADetailId], [Qty], [QtyToShip], [MasterCompanyId], [Status],
					[PickedById], [ConfirmedById], [Memo], [IsConfirmed], [QtyRemaining])
			VALUES(@RMAPickTicketNumber, @VendorRMAId, @CreatedBy, @UpdatedBy, GETDATE(), GETDATE(), @IsActive, @IsDeleted, 
					@VendorRMADetailId,
					([dbo].[fn_ConvertUOM](ISNULL(@Qty, 0),@PurchaseUnitOfMeasure,@StockUnitOfMeasure,0,@MasterCompanyId)), ([dbo].[fn_ConvertUOM](ISNULL(@QtyToShip, 0),@PurchaseUnitOfMeasure,@StockUnitOfMeasure,0,@MasterCompanyId)), @MasterCompanyId, @Status, @PickedById, @ConfirmedById, @Memo, @IsConfirmed, @QtyRemaining);

			SELECT @RMAPickTicketId = SCOPE_IDENTITY();

			IF (ISNULL(@EnforcePickTicketConfirmation, 0) = 0)
			BEGIN
				UPDATE [dbo].[RMAPickTicket] SET ConfirmedById = @PickedById, IsConfirmed = 1, ConfirmedDate = GETUTCDATE() WHERE RMAPickTicketId = @RMAPickTicketId;
			END

			IF(@CodePrefixId > 0 AND @CurrentNummber > 0)
			BEGIN
				UPDATE DBO.CodePrefixes SET CurrentNummber = @CurrentNummber WHERE CodePrefixId = @CodePrefixId;
			END
		END
		ELSE IF(@RMAPickTicketId > 0 AND @IsConfirmed = 0)
		BEGIN
			UPDATE [dbo].[RMAPickTicket] SET QtyToShip = ([dbo].[fn_ConvertUOM](ISNULL(@QtyToShip, 0),@StockUnitOfMeasure,@PurchaseUnitOfMeasure,0,@MasterCompanyId)),UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() WHERE RMAPickTicketId = @RMAPickTicketId;

			SELECT @QtyRemaining = (vra.Qty - SUM(ISNULL(rmp.QtyToShip, 0))) 
			FROM VendorRMADetail vra WITH(NOLOCK)
			--INNER JOIN SalesOrderReserveParts sorpp WITH(NOLOCK) ON vra.VendorRMAId = sorpp.SalesOrderId AND vra.ved = sorpp.SalesOrderPartId   
			LEFT JOIN RMAPickTicket rmp WITH(NOLOCK) ON vra.VendorRMAId = rmp.VendorRMAId and vra.VendorRMADetailId = rmp.VendorRMADetailId
			WHERE vra.VendorRMADetailId = @VendorRMADetailId GROUP BY vra.Qty

			UPDATE [dbo].[RMAPickTicket] SET QtyToShip = ([dbo].[fn_ConvertUOM](ISNULL(@QtyToShip, 0),@PurchaseUnitOfMeasure,@StockUnitOfMeasure,0,@MasterCompanyId)),UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE(), [QtyRemaining] = ([dbo].[fn_ConvertUOM](ISNULL(@QtyRemaining, 0),@StockUnitOfMeasure,@PurchaseUnitOfMeasure,0,@MasterCompanyId)) WHERE RMAPickTicketId = @RMAPickTicketId;

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