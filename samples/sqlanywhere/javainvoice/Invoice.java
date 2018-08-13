// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
// 
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.  
// 
// *********************************************************************

import java.io.*;

public class Invoice 
{
    public static String lineItem1Description;
    public static double lineItem1Cost;

    public static String lineItem2Description;
    public static double lineItem2Cost;

    public static double totalSum() {
	double runningsum;
	double taxfactor = 1 + Invoice.rateOfTaxation();

	runningsum = lineItem1Cost + lineItem2Cost;
	runningsum = runningsum * taxfactor;

	return runningsum;
    }

    public static double rateOfTaxation()
    {
	double rate;
	rate = .15;

	return rate;
    }

    public static void init( 
      String item1desc, double item1cost,
      String item2desc, double item2cost )
    {
	lineItem1Description = item1desc;
	lineItem1Cost = item1cost;
	lineItem2Description = item2desc;
	lineItem2Cost = item2cost;
    }

    public static String getLineItem1Description() 
    {
	return lineItem1Description;
    }

    public static double getLineItem1Cost() 
    {
	return lineItem1Cost;
    }

    public static String getLineItem2Description() 
    {
	return lineItem2Description;
    }

    public static double getLineItem2Cost() 
    {
	return lineItem2Cost;
    }

    public static boolean testOut( int[] param )
    {
	param[0] = 123;
	return true;
    }

    public static void main( String[] args )
    {
	System.out.print( "Hello" );
	for ( int i = 0; i  < args.length; i++ )
	    System.out.print( " " + args[i] );
	System.out.println();
    }
}
